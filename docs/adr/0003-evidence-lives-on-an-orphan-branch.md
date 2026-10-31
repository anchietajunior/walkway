# Evidence lives on an orphan branch

Validation screenshots and Mocks are pushed to an orphan `walkway-evidence` branch, under one folder per issue, and the draft PR embeds them by URL. GitHub offers no API to upload images into a PR, so the files need a home in the repository; committing them to the Task branch would ship them with the product code, and the unversioned `.walkway/` folder cannot be linked. The cost is one extra branch in the repository that grows with every Task and needs occasional pruning.
