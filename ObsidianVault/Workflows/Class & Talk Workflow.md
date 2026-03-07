### `arrive` before editing any course/talk materials
### Edit with fast updates
- Course/talk repos (e.g., `MATH476Spring2026`)
	- Slide content
	- Webpage content
	- Notebooks
	- Yaml
- Shared content in `classlib` submodules of course/talk repos
	- Slides
	- Webpages
	- Notebooks
	- Stylesheets, LaTeX macros, yaml
- Render locally _in the class talk root_ and _in the `qmcpy` environment_
	* `quarto-slides-live <slide file name>` for slides
	* `quarto preview .` for webpages
### Edit Python helpers for notebooks and slides directly in `HickernellClassLib` and push to Git so that they will take effect
### `push` changes to course/talk repos 
* Normally via VS code or GitKraken
* Before publishing `classlib` edits
### `publish-classlib-here "commit message"` to publish changes to `HickernellClassLib` 
* Only after pushing changes to local repos
### Other submodules
* Commit and push changes to `HickernellTestsArchive` directly
* Because `QMCSoftware` is maintained by a team, changes to develop require pull requests
### `depart` to propagate edits to Git and to other repos 
* Ensures that Git repository has an updated copy of all repos and will run Git Actions to produce updated pages and slides
* Ensures that `arrive` at the next machine will fetch the most updated copy
* You may continue to edit after `depart`
### `depart` before leaving machine
### Prototype locally. Promote intentionally.
