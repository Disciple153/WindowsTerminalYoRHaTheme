This theme is for use with Windows Terminal. It will not work with the vanilla command prompt, Pwereshell, or WSL (all of these can be used in Windows Terminal). Windows terminal can be downloaded here: https://www.microsoft.com/store/productId/9N0DX20HK701

To use this theme:
1. Move this folder wherever you like and note the path.
2. On the dropdown at the top of Windows Terinal, open settings.
3. The settings file will open. Under `profiles.defaults` paste the following code, taking care to change `[Path to YoRHa]` to the path you chose in step 1.

```json
"backgroundImage": "C:\\[Path to YoRHa]\\YoRHa\\YoRHa.png",
"foreground": "#daa",
"experimental.pixelShaderPath": "C:\\[Path to YoRHa]\\YoRHa\\NieR.hlsl",
"padding": "50, 0, 0, 0"
```