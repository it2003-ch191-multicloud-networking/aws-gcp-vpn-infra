# Cloudflare Zero Trust VPN Setup

This guide walks you through setting up Cloudflare Zero Trust (WARP) to securely access private resources in your GCP and AWS networks using Google OAuth authentication.

## Architecture Overview

```ascii
User (WARP Client) 
    ↓ (Google OAuth)
Cloudflare Zero Trust
    ↓
Cloudflare Tunnels (cloudflared)
    ├─→ GCP VM (Private Network)
    └─→ AWS EC2 (Private Network)
```

## Prerequisites

- Cloudflare account with Zero Trust enabled
- Google Cloud project for OAuth
- Access to GCP VM and AWS EC2 instances
- Domain managed by Cloudflare (optional but recommended)

## Part 1: Cloudflare Dashboard Setup

### Step 1: Enable Zero Trust

1. Log in to your Cloudflare dashboard
2. Go to **Zero Trust** section (or visit https://one.dash.cloudflare.com/)
3. Create a new team name (e.g., `your-company-team`)
4. 
### Step 2: Configure Google OAuth Authentication

1. **In Cloudflare Dashboard:**
   - Navigate to **Settings** → **Authentication**
   - Click **Add new** under Login methods
   - Select **Google**

2. **In Google Cloud Console:**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Select your project or create a new one
   - Navigate to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **OAuth 2.0 Client ID**
   - Configure the OAuth consent screen if prompted:
     - User Type: External (or Internal for Google Workspace)
     - Add your email to test users
     - Scopes: email, profile, openid
   - Application type: **Web application**
   - Name: `Cloudflare Zero Trust`
   - Authorized redirect URIs:
     ```
     https://your-company-team.cloudflareaccess.com/cdn-cgi/access/callback
     ```
   - Copy the **Client ID** and **Client Secret**

3. **Back in Cloudflare:**
   - Paste the Client ID and Client Secret
   - (Optional) Restrict to specific Google Workspace domain
   - Click **Save**

### Step 3: Create a Device Enrollment Policy

1. Go to **Settings** → **WARP Client**
2. Click **Device enrollment**
3. Create a new rule:
   - Rule name: `Allow OAuth Users`
   - Rule action: **Allow**
   - Configure rule:
     - Selector: **Emails**
     - Value: Your email or use **Emails ending in**: `@yourdomain.com`
   - Click **Save**

### Step 4: Configure Split Tunnels

1. Go to **Settings** → **WARP Client** → **Device settings**
2. Click on **Default** profile or create a new one
3. Configure **Split Tunnels**:
   - Mode: **Exclude** or **Include** mode
   - For **Include mode**, add your private network CIDRs:
     ```
     10.0.0.0/16    (AWS VPC CIDR)
     10.10.0.0/16    (GCP VPC CIDR)
     ```
   - This ensures only private network traffic goes through the tunnel

4. Enable **Gateway with WARP** mode

### Step 5: Create Cloudflare Tunnels

1. Go to **Networks** → **Tunnels**
2. Click **Create a tunnel**
3. Choose **Cloudflared**
4. Name your tunnel: `aws-tunnel`
5. **Important**: Copy the tunnel token shown - you'll need this for EC2
   - Format: `eyJhIjoiXXXXXXXX...`
6. Click **Next**
7. Configure Private Network:
   - Add CIDR: `10.0.0.0/16` (your AWS VPC CIDR)
8. Click **Save tunnel**

9. Repeat for GCP:
   - Create another tunnel: `gcp-tunnel`
   - Copy the tunnel token
   - Add CIDR: `10.10.0.0/16` (your GCP VPC CIDR)

### Step 6: Configure Gateway Policies (Optional)

1. Go to **Gateway** → **Firewall Policies**
2. Create policies to control access to specific resources
3. Example policy:
   - Name: `Allow Nginx Access`
   - Traffic: Private Network
   - Selector: Destination IP
   - Value: Your nginx server IP
   - Action: Allow

## Part 2: Server Setup (GCP VM & AWS EC2)

### Prerequisites on Each Server

Both GCP VM and AWS EC2 need:
- Docker and Docker Compose installed
- Outbound internet access (to connect to Cloudflare)
- Tunnel tokens from Cloudflare dashboard

### Deploy on AWS EC2 and GCP VM

1. SSH into your EC2 instance and GCP VM
2. Navigate to installation directory:
   ```bash
   cd /home/ubuntu/cloudflare-tunnel
   ```
3. Set your tunnel token in install file:
   ```bash
   sudo ./install.sh
   ```

## Part 3: Client Setup

### Install WARP Client

**macOS:**
```bash
brew install --cask cloudflare-warp
```

**Windows:**
- Download from: https://1.1.1.1/
- Install the executable

**Linux:**
```bash
# Ubuntu/Debian
curl https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
sudo apt update && sudo apt install cloudflare-warp
```

### Configure and Connect

1. Open the WARP application
2. Click on the gear icon (Settings)
3. Go to **Preferences** → **Account**
4. Click **Login with Cloudflare Zero Trust**
5. Enter your team name: `your-company-team`
6. Authenticate with Google OAuth
7. Once authenticated, toggle WARP to **Connected**

## Part 4: Testing Access

### Verify Tunnel Status

1. In Cloudflare Dashboard, go to **Networks** → **Tunnels**
2. Both tunnels should show status: **Healthy** (green)

### Test Private Network Access

1. Ensure WARP is connected
2. Try accessing private resources:
   ```bash
   # Test EC2 nginx (private IP)
   curl http://10.0.1.10
   
   # Test GCP VM nginx (private IP)
   curl http://10.1.1.10
   
   # Test with hostname if DNS configured
   curl http://nginx.internal
   ```

3. You should see the nginx response page

## Security Best Practices

1. **Use Device Posture Checks:**
   - Enable device posture checks in Zero Trust settings
   - Require disk encryption, firewall enabled, OS version

2. **Implement Access Policies:**
   - Create granular policies for different resources
   - Use identity-based access control
   - Regularly review access logs

3. **Monitor and Audit:**
   - Enable logging in Gateway settings
   - Review access logs regularly: **Logs** → **Gateway** → **Network**
   - Set up alerts for suspicious activity

4. **Rotate Tunnel Tokens:**
   - Periodically rotate tunnel credentials
   - Use separate tunnels for different environments

## Additional Resources

- [Cloudflare Zero Trust Documentation](https://developers.cloudflare.com/cloudflare-one/)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [WARP Client Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/)
