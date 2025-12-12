
### 🔍 Checking When Apps Were Last Updated

You can check when apps were last updated in several ways, depending on how they were installed.

#### 1. Homebrew Casks
To see when GUI apps installed via Homebrew were last updated:
```bash
ls -lt /usr/local/Caskroom | head -20      # Intel Mac
ls -lt /opt/homebrew/Caskroom | head -20   # Apple Silicon Mac
```
Each folder’s timestamp shows when that cask was last modified (i.e., last updated).  
Example:
```
drwxr-xr-x  4 fredjhickernell  admin  128 Nov  1 09:32 visual-studio-code
```
→ Visual Studio Code last updated on **Nov 1 09:32**.

#### 2. App Store (MAS) Apps
If an app like WhatsApp or Pages was installed via the App Store (through `mas` in your Brewfile), it will **not** appear in `Caskroom`.  
Instead, check its bundle directly:
```bash
mdls -name kMDItemVersion -name kMDItemContentModificationDate /Applications/WhatsApp.app
```
This shows both the **version** and the **last modification date** for that app.

#### 3. All Applications
To get a quick overview of all apps’ modification dates:
```bash
stat -f "%Sm %N" /Applications/*.app | sort
```
That lists every `.app` bundle in `/Applications` by its last modification date.

---

