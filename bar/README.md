## Dependencies

To use the bar, you must have the following core components installed on your system:

### Required

- **[Quickshell](https://quickshell.org):** The engine used to render the QML interface and provide the necessary Wayland desktop shell integrations.

## Getting Started

### 1. Run [Install Script](/install.sh)

### 2. Run Quickshell

```bash
# Set rounding policy to prevent anti-aliasing artifacts on fractional scales
QT_SCALE_FACTOR_ROUNDING_POLICY=Round qs --path /opt/ctos/bar.qml
```
