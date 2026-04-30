package providers

import (
	"bytes"
	"compress/gzip"
	"context"
	"io"
	"net/http"
	"os"

	"github.com/bfibraga/turntide/fetcher/internal/download"
)

const (
	AllPrintingsURL string = "https://mtgjson.com/api/v5/AllPrintings.sqlite.gz"
)

var (
	content []byte
)

func MTGJSONDownload(dbPath string) error {
	return download.NewDownloadProviderBuilder().
		WithSteps(
			httpRequest(AllPrintingsURL),
			parseSaveContent(dbPath),
		).
		Download()
}

func httpRequest(url string) func(ctx context.Context) error {
	return func(ctx context.Context) error {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			return err
		}

		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			return err
		}
		defer resp.Body.Close()

		var buf bytes.Buffer
		_, err = io.Copy(&buf, resp.Body)
		if err != nil {
			return err
		}
		content = buf.Bytes()

		return nil
	}
}

func parseSaveContent(dbPath string) func(ctx context.Context) error {
	return func(ctx context.Context) error {
		decoded, err := decodeGzip()
		if err != nil {
			return err
		}

		_, err = os.Stat(dbPath)
		if err == nil {
			return nil
		}

		err = os.WriteFile(dbPath, decoded, 0644)

		return err
	}
}

func decodeGzip() ([]byte, error) {
	reader, err := gzip.NewReader(bytes.NewReader(content))
	if err != nil {
		return nil, err
	}
	defer reader.Close()

	var buf bytes.Buffer
	_, err = io.Copy(&buf, reader)
	if err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}
