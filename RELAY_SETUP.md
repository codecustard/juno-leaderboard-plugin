# Internet Identity Relay Page Setup

The Juno Leaderboard plugin requires a relay web page to handle Internet Identity authentication for desktop applications. This page bridges the gap between Internet Identity (which requires a web browser) and your Godot game (which runs natively).

**✨ Auto-Detection:** The plugin automatically constructs the relay URL from your satellite ID: `https://{your-satellite-id}.icp0.io/relay.html`. Just upload `relay.html` to your satellite and you're done!

## Why is this needed?

Internet Identity uses browser APIs and postMessage for authentication, which don't work directly with desktop applications. The relay page:
1. Handles II authentication in the browser
2. Gets the delegation chain
3. Redirects back to localhost with the delegation

This is the **standard pattern** used by ICP desktop applications (DSCVR, Unity SDK, etc.).

## Quick Setup (Juno Satellite Storage - Recommended)

Since you're already using Juno for your leaderboard, hosting the relay page on your satellite is the simplest option!

### Method 1: Upload via Juno Console (Easiest)

1. **Open Juno Console**: https://console.juno.build
2. **Select your satellite** (the same one you're using for the leaderboard)
3. **Go to "Hosting" or "Storage" section**
4. **Upload `relay.html`**:
   - Find the file in your plugin folder: `addons/juno_leaderboard/../../relay.html`
   - Upload it to the root of your satellite
5. **Done!** The plugin will automatically use: `https://YOUR_SATELLITE_ID.icp0.io/relay.html`

No configuration needed - it auto-detects your satellite ID!

### Method 2: Upload via Juno CLI

```bash
# Install Juno CLI (if not already installed)
npm install -g @junobuild/cli

# Navigate to your project
cd /path/to/juno-leaderboard-plugin

# Update juno.config.json with your satellite ID:
# Edit the file and replace YOUR_SATELLITE_ID with your actual satellite ID

# Deploy relay.html to your satellite
juno deploy

# The relay page is now accessible at: https://YOUR_SATELLITE_ID.icp0.io/relay.html
```

**Note:** A `juno.config.json` file is included in the plugin folder. Just update the `satellite.id` field with your satellite ID before deploying.

## Alternative Hosting (GitHub Pages, Vercel, etc.)

If you prefer external hosting:

1. **Create a new GitHub repository** (or use existing one):
   ```bash
   # Example: my-juno-relay
   ```

2. **Copy `relay.html`** to your repository

3. **Enable GitHub Pages**:
   - Go to repository Settings → Pages
   - Source: Deploy from a branch
   - Branch: `main` (or `master`)
   - Folder: `/ (root)`
   - Click Save

4. **Update your game to use your custom relay URL**:
   ```gdscript
   # In your Godot script, before calling login():
   Juno._juno_native.set_relay_url("https://YOUR_USERNAME.github.io/YOUR_REPO/relay.html")

   # Or check current relay URL:
   print("Relay URL: ", Juno._juno_native.get_relay_url())
   ```

5. **Wait a few minutes** for GitHub Pages to deploy

6. **Test the URL** in your browser - you should see the relay page

## Alternative Hosting Options

### Vercel
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
cd /path/to/relay/folder
vercel
```

### Netlify
1. Drag and drop the `relay.html` file into [Netlify Drop](https://app.netlify.com/drop)
2. Get your URL: `https://YOUR_SITE.netlify.app/relay.html`

### Your Own Web Server
Host `relay.html` on any static web server. Just ensure:
- HTTPS is enabled (required for II)
- CORS is not blocking localhost redirects

## How It Works

```
┌─────────────┐
│  Godot Game │
└──────┬──────┘
       │ 1. Generate session keypair
       │ 2. Start localhost HTTP server
       │ 3. Open relay page URL
       ▼
┌─────────────┐
│ Relay Page  │ (in browser)
│ (GitHub     │
│  Pages)     │
└──────┬──────┘
       │ 4. Redirect to II
       ▼
┌─────────────┐
│  Internet   │
│  Identity   │
└──────┬──────┘
       │ 5. User authenticates
       │ 6. Returns delegation to relay
       ▼
┌─────────────┐
│ Relay Page  │
└──────┬──────┘
       │ 7. Redirect to localhost:PORT/callback?delegation=...
       ▼
┌─────────────┐
│ HTTP Server │ (in Godot game)
│ localhost   │
└──────┬──────┘
       │ 8. Delegation received
       │ 9. Emit login_completed signal
       ▼
┌─────────────┐
│  Godot Game │ (authenticated!)
└─────────────┘
```

## Security Notes

- The relay page is **open source** and **client-side only** (no backend)
- No sensitive data is stored or logged
- The delegation is transmitted via HTTPS → localhost redirect
- Localhost HTTP is secure as it's local-only (cannot be accessed from network)
- Session keypair is generated fresh each login and never leaves your machine

## Troubleshooting

### "Relay page doesn't load"
- Check that GitHub Pages is enabled
- Wait 5-10 minutes after enabling Pages
- Verify the URL in your browser

### "Authentication hangs"
- Check browser console for errors
- Ensure the callbackUrl is accessible (localhost server running)
- Try refreshing the relay page

### "Delegation not received"
- Check Godot console for errors
- Verify HTTP server is listening (should see "Callback server listening on...")
- Try with a longer timeout

## Custom Relay Page

You can customize `relay.html` to match your game's branding:
- Change colors in the `<style>` section
- Update text/logos
- Add analytics (optional)

**Important:** Don't modify the JavaScript logic unless you know what you're doing!

## Support

For issues with the relay page:
1. Check browser console (F12)
2. Check Godot console for errors
3. File an issue at: https://github.com/codecustard/juno-leaderboard-plugin/issues
