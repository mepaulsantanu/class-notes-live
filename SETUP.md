# Setup guide

Everything here runs on a Mac. Keep the project in your home folder (for example `~/class-notes-live`), not in Desktop, Documents or Downloads, so the scheduled job is not blocked by macOS privacy settings.

## 1. Install the tools

Open the Terminal app and check each one:

```
node -v
git --version
claude --version
```

- No Node? Install the LTS version from nodejs.org.
- No git? Run `xcode-select --install`.
- No Claude Code? Follow the install steps at docs.claude.com for Claude Code, then run `claude` once and sign in.

## 2. Connect Claude Code to NeoSapien (the key test)

```
claude mcp add --transport http --scope user neosapien https://api.neosapien.xyz/mcp
claude
```

Inside Claude Code, type `/mcp`, choose **neosapien**, then **Authenticate**. Your browser opens; log in to NeoSapien. Then ask: `List my NeoSapien recordings from today.`

If it lists them, continue. If the login fails, this project cannot fetch data; keep using the claude.ai version.

## 3. Put the project on GitHub

1. On github.com, click **+**, then **New repository**. Name it `class-notes-live`. Choose **Public** (free GitHub Pages needs it). Do not add a README.
2. In Terminal:

```
cd ~
unzip ~/Downloads/class-notes-live.zip
cd class-notes-live
git init
git add .
git commit -m "First version"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/class-notes-live.git
git push -u origin main
```

GitHub asks you to sign in the first time. If it asks for a password, create a personal access token at github.com, Settings, Developer settings, Personal access tokens, and paste that instead.

3. Check that `data/private/` is not on GitHub. It is listed in `.gitignore`, so it never uploads.

## 4. Turn on the website

On GitHub, open the repository, then **Settings, Pages**. Set **Source** to **Deploy from a branch**, **Branch** to **main**, folder **/docs**, and click **Save**. After a minute or two the page shows your link: `https://YOUR-USERNAME.github.io/class-notes-live/`. Put it in README.md.

## 5. Run the sync once by hand

```
cd ~/class-notes-live
./sync/sync.sh
```

Watch the output. A healthy run ends with `published` or `no changes`. The first time, Claude Code may ask you to approve tools; approve them, then run it again.

## 6. Turn on auto-sync

```
./sync/install-autosync.sh
```

That's it. From now on:

- **Your laptop does not need to stay on.** Close it whenever you like.
- When you open it after a lecture, a sync starts within about a minute. It catches up on everything recorded while the laptop was closed (up to 7 days back).
- **Keep the lid open for about 3 to 5 minutes** when there are new lectures, so Claude can finish writing the notes. With nothing new, a run takes under a minute.
- While the laptop stays awake, it also checks every 15 minutes.
- Your website stays online all the time on GitHub Pages, showing the latest published notes.

**Want to sync right now?** Double-click **Sync now.command** in the project folder. A window shows progress and says "Finished" when done. The first time, macOS may block it: right-click it, choose **Open**, then **Open** again.

**Check it worked:** open `sync/sync.log`. Each run ends with `published` (new notes went live) or `no changes`.

**Turn auto-sync off:** `launchctl unload -w ~/Library/LaunchAgents/com.classnoteslive.sync.plist`

If a run is cut short because you closed the lid, nothing breaks. The next run picks up where it stopped.

## Keep background syncs logged in (do this once a year)

Your normal Claude Code login expires after a while, and background syncs cannot renew it. Create a one-year login just for the sync:

```
claude setup-token
```

Approve it in the browser, then copy the token it prints (it starts with `sk-ant-oat01-`) and save it:

```
mkdir -p ~/.config/class-notes && pbpaste > ~/.config/class-notes/claude-token && chmod 600 ~/.config/class-notes/claude-token
```

(Copy the token first with Cmd + C, because `pbpaste` saves whatever is on your clipboard.) The token never goes to GitHub. You get a Mac notification if any login expires again.

## Everyday use

- **New announcement or deadline:** edit `data/announcements.json` (copy an existing entry, change the id, title, course, kind, due and details), then run `./sync/sync.sh` or just `git add`, `commit` and `push`.
- **New trimester:** update `data/timetable.json` with the new slots and dates.
- **A recording landed in the wrong course:** add its id to `data/allowlist.json` with the right course (or remove it), delete the matching note in `data/notes/`, and run the sync again.

## Costs

GitHub, GitHub Pages and the auto-sync job are free. The fetch and note-writing steps run on Claude Code and count toward your Claude plan's usage.
