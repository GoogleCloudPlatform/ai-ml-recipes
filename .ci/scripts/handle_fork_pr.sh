#!/bin/bash
set -e

PR_NUMBER=$1

# Ensure PR_NUMBER is provided
if [ -z "$PR_NUMBER" ]; then
  echo "Error: Pull Request number not provided."
  exit 1
fi

DIFF_CONTENT=$(git diff --staged)

# Create the comment body in a file
cat &lt;&lt;EOF &gt; comment.md
## 🤖 AI-Powered Notebook Enhancement Suggestions

I've analyzed your notebook(s) and generated some enhancements. Since this is a fork PR, I can't commit directly, but here are the suggested changes:

&lt;details&gt;
&lt;summary&gt;📋 View suggested changes&lt;/summary&gt;

\`\`\`diff
$DIFF_CONTENT
\`\`\`

&lt;/details&gt;

### How to apply these changes:
1. Run the enhancement scripts locally:
   \`\`\`bash
   python .ci/scripts/enhance_notebook.py
   python .ci/scripts/generate_docs.py
   \`\`\`
2. Or manually apply the changes shown above

---
*This comment was generated automatically by the AI notebook enhancement workflow.*
EOF

# Post the comment using the file
gh pr comment "$PR_NUMBER" --body-file comment.md
