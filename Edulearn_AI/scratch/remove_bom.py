with open('.env', 'rb') as f:
    content = f.read()

if content.startswith(b'\xef\xbb\xbf'):
    print("Found BOM, removing it...")
    with open('.env', 'wb') as f:
        f.write(content[3:])
    print("BOM removed.")
else:
    print("No BOM found.")
