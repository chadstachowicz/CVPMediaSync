This small script that will turn any windows folder into a repository for CVP.

Some important features.

- Directory acts as repo
- Understands and replicates all files including directory structure
- If a media file exists, it backs it up before overwriting it
- It has some detailed logging
- There is a config file to help you add as many media server as you like
- This should be scheduled under Task Manager after ruby is installed, every 10 minutes.  Also make sure to export the task and change the priority to 0.  I will upload a task .xml to use shortly.

Lastly make sure to use ruby 1.8.7 since FileUtils on Windows is a bear currently to get installed.

