# Blog and Medium

Text for careful reading: someone arrived from a search or a recommendation and wants to understand the subject in depth. 800 to 1,800 words. Explain the why, show concrete examples (commands, code, numbers) and cite sources where they are used.

## Structure

1. **Title and subtitle.** The title carries the term the reader would search for. The subtitle is one sentence on what they take away.
2. **Opening**: the problem and the author's context in the first paragraph. By the end of the second, the reader knows what they will learn.
3. **`##` sections**: one idea each, in the order the reader needs them. Code in fenced blocks with the language set. Links inline, where the source is used.
4. **Conclusion**: what the author would do differently, what is still open, or the next step. Something new, not a summary.
5. **References** section (`##`): every link used, with its title.
6. **Image suggestions** section (`##`): a cover image (with alt text) and up to two body images, each naming the section it goes in. Same suggestion format as LinkedIn: bold name, description, prompt when generated.

Headings are written in the article's language.

## Per destination

**Own blog** (`<slug>-blog.md`): start with YAML frontmatter for the site generator:

```yaml
---
title: "..."
description: "subtitle, up to 160 characters"
date: YYYY-MM-DD
tags: [tag1, tag2]
---
```

If the author has earlier blog posts, copy their frontmatter fields instead of these.

**Medium** (`<slug>-medium.md`): no frontmatter. Title on the first line as `#`, subtitle on the second as plain text. Adjustments, because Medium's editor does not accept everything:

- Medium has no tables: turn each table into a list, or suggest it as an image.
- Use only two heading levels (`#` and `##`).
- At the end, a `Tags:` line with up to 5 tags, Medium's limit.
- If the text was already published on the author's blog, say in the report to publish it through Medium's "Import a story", which keeps the canonical link pointing to the blog.
