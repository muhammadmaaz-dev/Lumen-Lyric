with open('backend/main.py', 'r', encoding='utf-8') as f:
    text = f.read()

import re
# Fix second merge conflict block
text = re.sub(r'<<<<<<< HEAD.*?=======\n', '', text, flags=re.DOTALL)
text = re.sub(r'>>>>>>>.*?\n', '', text)

with open('backend/main.py', 'w', encoding='utf-8') as f:
    f.write(text)
