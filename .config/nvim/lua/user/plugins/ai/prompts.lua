require('gen').prompts['Complete_Code'] = {
  prompt = "Complete the following code:\n```$filetype\n$text\n```\nProvide only the code continuation, no explanations:",
  replace = true
}

require('gen').prompts['Explain_Code'] = {
  prompt = "Explain this $filetype code step by step:\n```$filetype\n$text\n```",
  replace = false
}

require('gen').prompts['Add_Comments'] = {
  prompt = "Add detailed comments to this code:\n```$filetype\n$text\n```",
  replace = true
}

require('gen').prompts['Optimize_Code'] = {
  prompt = "Optimize this code for performance and readability:\n```$filetype\n$text\n```",
  replace = true
}
