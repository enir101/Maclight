# PauseRemapper

## Overview

QOL Improvements for Mac on Moonlight

---

## Usage

### macOS (Lua)

1. Add `init.lua` to your Hammerspoon configuration directory (usually `~/.hammerspoon/`).

---

### Windows (C#)

1. **Build the executable**
   Open a terminal and run:

   ```bash
   dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true
   ```

   This will generate a self-contained `PauseRemapper.exe` file.

2. **Copy the executable to your Windows machine.**

3. **Add to Task Scheduler**

   * Press `Win + R`, type `taskschd.msc`, and hit Enter.
   * Click **Create Task** (do **not** select "Create Basic Task").

   **General tab:**

   * Name: `PauseRemapper`
   * Check **Run with highest privileges**

   **Triggers tab:**

   * Click **New** → **Begin the task:** `At log on` → Click **OK**

   **Actions tab:**

   * Click **New** → **Action:** `Start a program` → Browse to your `PauseRemapper.exe` → Click **OK**

   * Click **OK** again to save the task.