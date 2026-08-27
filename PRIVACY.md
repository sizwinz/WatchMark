# Privacy Policy for WatchMark

**Last Updated:** August 28, 2026

WatchMark ("we", "our", or "the application") is a local-first, open-source movie and series tracking application. We are committed to complete privacy and transparency. This Privacy Policy explains how WatchMark handles your data.

---

## 1. Summary of Core Principles

- **Local-First by Default:** All your library items, watch history, sessions, progress timestamps, ratings, and custom lists are stored locally on your device in an encrypted/private SQLite database.
- **Zero Telemetry and Tracking:** WatchMark contains zero tracking SDKs, zero analytics services, zero advertising frameworks, and zero crash-reporting servers.
- **No Third-Party User Accounts Required:** You do not need to create an account with us to use WatchMark.
- **User Ownership:** You own your data. You can export a complete JSON backup at any time or delete your data permanently.

---

## 2. Information We Collect and Process

### A. Local Tracking Data
When you use WatchMark, the application stores the following information locally on your device:
- Media items added to your library (Watchlist, Watching, Paused, Completed, Dropped).
- Watch progress (playback timestamp in seconds, season and episode numbers).
- Watch sessions (start time, end time, duration watched, streaming provider tag).
- Custom watchlists and collections created by you.
- User application preferences (theme selection, custom TMDB API keys).

This data never leaves your device unless you explicitly connect Google Drive synchronization.

### B. Third-Party Metadata Services (The Movie Database - TMDB)
To provide search results, posters, backdrops, cast information, and episode summaries, WatchMark queries the public TMDB API (v3):
- Search queries (e.g. title names) and media IDs are sent directly from your device to TMDB servers over secure HTTPS.
- WatchMark does not send your personal identity, watch history, or viewing progress to TMDB.
- TMDB's privacy policy governs queries sent to their API: [TMDB Privacy Policy](https://www.themoviedb.org/privacy-policy).

### C. Optional Cloud Synchronization (Google Drive)
If you choose to enable cloud synchronization:
- WatchMark uses Google OAuth to authenticate with your personal Google account.
- **Restricted Scope (`appDataFolder`):** WatchMark requests access only to its private application folder (`https://www.googleapis.com/auth/drive.appdata`). It cannot access, read, or modify any other files or folders in your Google Drive.
- Synchronization works by uploading JSONL event logs directly between your device and your personal Google Drive storage. No intermediate server or backend proxies this connection.
- You can disconnect Google Drive sync or delete your synced cloud data at any time from within the application's settings or your Google Account management page.

---

## 3. Data Storage and Security

- **On-Device Security:** Local database files and cached media metadata are stored inside your device's isolated application storage sandbox.
- **Credential Storage:** Sensitive tokens (such as custom TMDB API keys and OAuth tokens) are stored using platform-native secure storage mechanisms (Android KeyStore, Windows Credential Manager, Linux Secret Service, and macOS Keychain).
- **No Remote Servers:** The developers of WatchMark do not operate servers that store, process, or transmit your watch logs or identities.

---

## 4. Children's Privacy

WatchMark does not knowingly collect or solicit personal information from children under the age of 13. The application is a local utility that does not harvest personal user details.

---

## 5. Changes to This Privacy Policy

Because WatchMark is an open-source project, any future updates to this Privacy Policy will be reflected directly in the project repository with clear version history.

---

## 6. Open Source and Source Code Verification

WatchMark is published under the GNU General Public License v3.0 (GPL-3.0). You can inspect, audit, and compile the entire source code independently on GitHub:
- Repository: [https://github.com/sizwinz/WatchMark](https://github.com/sizwinz/WatchMark)

---

## 7. Contact Information

If you have any questions, concerns, or requests regarding this Privacy Policy, you can open an issue on our official GitHub repository:
- GitHub Issues: [https://github.com/sizwinz/WatchMark/issues](https://github.com/sizwinz/WatchMark/issues)
