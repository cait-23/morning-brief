# Morning Brief (template)

A one-page morning brief and planner, made with Claude. The top of the page shows your day:
the date in cut-out newspaper letters, a one-line summary, and a timeline of your meetings.
Below that is what needs your attention and what has already been resolved. The planner
side has a sticky note for today's priorities, two to-do lists, an hour-by-hour plan and
a habit tracker.

The sticky note is decorated with **photo stickers** (dog photos in this example) that
change every day. You can swap in your own photos: your pet, your kids, your garden,
anything.

This copy contains **example content only**. Your own brief fills in from your calendar,
email and chat when Claude refreshes it.

---

## What's in this folder

| File | What it is |
|---|---|
| `index.html` | The whole page: layout, styles and code in one file |
| `dogs/dog-01.png` to `dog-06.png` | Six example photo stickers (the daily rotation) |
| `dog1.png`, `dog3.png` | Two stickers shown for a moment before the rotation loads |
| `mug.png`, `star*.png` | Decorations around the date and the sticky note |
| `cursor-pink.png` | The pink star mouse cursor |
| `tools/make-stickers.ps1` | A Windows script that turns photos into stickers |

---

## Setting up your own brief

1. In Claude (Claude Code or the Claude app), connect your calendar and email, for
   example Microsoft 365 or Google.
2. Give Claude this folder and ask: *"Publish this morning brief as an artifact, with
   all the images in the folder."*
3. Each morning, ask: *"Refresh my morning brief."* Claude reads your calendar, email
   and chat and rewrites the brief section. It doesn't touch the planner or stickers.

Your priorities, to-dos, plans and habits save privately to your own account. No one
else who opens the page can see them.

---

## Making your own photo stickers

Each sticker is a photo with the background removed and a white border added, saved
as a PNG. The page shows two each day and works through all of them before repeating.
Clicking a sticker peels it off and sticks on a different one.

### Step 1: Remove the backgrounds

Pick photos where your subject is clear and not cut off much at the edges. Six or more
is a good start; you need at least three.

**On an iPhone (does a whole album at once)**

Put your photos in one album, then build a shortcut in the **Shortcuts** app:

1. Tap **+** to make a new shortcut.
2. Add **Find Photos**. Tap **Add Filter** and set **Album · is ·** *your album*.
   Turn off **Limit** so it uses every photo.
3. Add **Repeat with Each**, set to **Photos**.
4. Inside the repeat, add **Remove Background** (from the Repeat Item).
5. Then add **Save to Photo Album** and choose a *different* album, for example
   "Stickers".
6. Run the shortcut.

To move the results to your computer: open the "Stickers" album, tap **Select**, then
**Select All**, then **Share → Save to Files**, and pick a folder in OneDrive or iCloud
Drive. If you see **Options** at the top of the share sheet, set the format to
**Current** to keep the transparent backgrounds.

**One photo at a time**

- iPhone or iPad: press and hold the subject in a photo, then tap **Share** or **Copy**.
- Windows 11: open the photo in the **Photos** app, click **Edit → Background →
  Remove**, then save a copy.
- Mac: in **Preview**, choose **Tools → Remove Background**.

It's fine if the result has a **white** background instead of a transparent one, for
example as a JPG. The script in Step 2 handles both.

### Step 2: Add the white sticker border

**Windows:** run the included script. It trims each photo, adds the white border,
resizes it and names the files in order (`dog-01.png`, `dog-02.png`, ...):

```powershell
powershell -ExecutionPolicy Bypass -File tools\make-stickers.ps1 `
  -SrcDir "C:\path\to\your\background-removed photos" `
  -OutDir "C:\path\to\this folder\dogs"
```

It also writes `check.png`, a contact sheet of every sticker, so you can look them over.
Delete it afterwards.

**Any computer:** ask Claude: *"Turn the photos in this folder into stickers with a
white border, named dog-01.png, dog-02.png, and so on."*

### Step 3: Tell the page how many stickers you have

1. Put the stickers in the `dogs` folder, replacing the examples.
2. Open `index.html`, search for `Photo stickers`, and change the setting below it:

   ```js
   var STICKER_FOLDER="dogs",STICKER_PREFIX="dog-",STICKER_COUNT=6;
   ```

   - `STICKER_COUNT`: how many stickers you have.
   - `STICKER_FOLDER` and `STICKER_PREFIX`: change these only if you rename the folder
     or files, for example `"cats"` and `"cat-"` for `cats/cat-01.png`.
3. Optional: replace `dog1.png` and `dog3.png` with any two of your stickers. They show
   for a split second while the page loads.
4. Ask Claude to republish the page with the new images.

---

## Other things you can change

- **Habits:** rename, add or remove them on the page with **Rename or remove**.
- **Decorations:** replace `mug.png` or any `star*.png` with your own images (PNGs with
  transparent backgrounds work best). Keep the same file names, or ask Claude to update
  the page.
- **Cursor:** replace `cursor-pink.png` with any 32×32 pixel PNG.
- **Anything else** (layout, colors, sections): describe the change to Claude.
