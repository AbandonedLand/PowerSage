sudo apt update
sudo curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
sudo apt install nodejs npm cmake libwebkit2gtk-4.1-dev build-essential curl wget file libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev clang libc6-dev
sudo npm install -g pnpm@latest-10

# Restart server

cargo install --git https://github.com/xch-dev/sage sage-cli --rev v0.9.5