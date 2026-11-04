--!strict
-- The opening mounts its opaque shield before App or the lobby is constructed.
require(script.Parent.Intro.IntroController).start(function(transitionFx)
	return require(script.Parent.App).start({deferIntro=true,transitionFx=transitionFx})
end)
