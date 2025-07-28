# FileFlows Homebrew Tap

This repository contains the Homebrew formula to install **FileFlows**.

---

## Adding the Tap

Add the FileFlows tap to your Homebrew:

```bash
brew tap fileflows/tap
```
---

## FileFlows Server


### Installing FileFlows

Install the FileFlows formula:

```bash
brew install fileflows
```

### Uninstalling FileFlows

Restart the service with:

```bash
brew uninstall fileflows
```

---

### Running the Service

Start the service with:

```bash
brew services start fileflows
```

Stop the service with:

```bash
brew services stop fileflows
```

Restart the service with:

```bash
brew services restart fileflows
```

---

### Running Manually

You can also run the FileFlows manually by executing:

```bash
fileflows
```

---


---

## FileFlows Node

---

### Installing FileFlows Node

Install the FileFlows Node formula:

```bash
brew install fileflows-node
```

### Uninstalling FileFlows Node

Restart the service with:

```bash
brew uninstall fileflows-node
```

---

### Configuration

Run the configuration command to set the server URL and optionally an access token:

```bash
fileflows-node --configure
```

You will be prompted to enter the Server URL (required).

You can enter an Access Token (optional).

This creates or updates the Data/node.config file inside the installation directory.

---

### Running the Service

Start the service with:

```bash
brew services start fileflows-node
```

Stop the service with:

```bash
brew services stop fileflows-node
```

Restart the service with:

```bash
brew services restart fileflows-node
```

---

### Running Manually

You can also run the FileFlows Node manually by executing:

```bash
fileflows-node
```

---

## Notes

- This formula uses a custom no-checksum download strategy to allow downloading a versioned zip without SHA verification.
- The launchd service is configured to run as your user (no root required).
- Configuration must be done once before starting the service.
