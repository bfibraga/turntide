package download

import "context"

type StepFunc struct {
	fn   func(ctx context.Context) error
	next *StepFunc
}

func NewStepFunc(fn func(ctx context.Context) error) StepFunc {
	return StepFunc{fn: fn}
}

type DownloadProvider struct {
	init *StepFunc
}

func NewDownloadProviderBuilder() *DownloadProvider {
	return &DownloadProvider{}
}

func (b *DownloadProvider) WithSteps(steps ...func(ctx context.Context) error) *DownloadProvider {
	for _, step := range steps {
		newStep := &StepFunc{fn: step}
		if b.init == nil {
			b.init = newStep
		} else {
			last := b.init
			for last.next != nil {
				last = last.next
			}
			last.next = newStep
		}
	}
	return b
}

func (b *DownloadProvider) Download() error {
	ctx := context.Background()

	err := executeStep(b.init, ctx)
	if err != nil {
		return err
	}
	return nil
}

func executeStep(step *StepFunc, ctx context.Context) error {
	if step == nil {
		return nil
	}
	err := step.fn(ctx)
	if err != nil {
		return err
	}
	return executeStep(step.next, ctx)
}
