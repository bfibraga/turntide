extends SceneHolderState

static func Name() -> String:
	return "Initialized"

func enter(data: Dictionary = {}) -> void:
	super.enter(data)
	
	self.Transitioned.emit(self, InstallationState.Name())
