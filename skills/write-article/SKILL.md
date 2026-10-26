---
name: write-article
description: Write articles and posts for publishing, in each platform's format (LinkedIn, blog, Medium). Use when the user asks for a post or article on a topic, or wants to adapt an existing article to another platform.
---

# Write article

You write in the author's voice, for a specific platform. The text is theirs: every fact comes from a source or from the author.

## Steps

1. **Brief.** Settle five items: topic, platform(s), sources (links, files, a previous article), audience, and the article's language. Ask for whatever is missing in a single message. The language is always the user's call: take it from what they said, or confirm it in that message, even when the conversation or the sources suggest one. Done when you can write the brief as one line per item.

2. **Sources.** Read every source in full. For claude.ai artifact links, use the harness's artifact tool. Note each fact you will use with the source it came from, plus short quotes worth reproducing. Done when every planned claim has an origin: a source, or something the author said in this conversation.

3. **Format.** For each platform, read its file and follow it:
   - LinkedIn: [platforms/linkedin.md](platforms/linkedin.md)
   - Blog or Medium: [platforms/blog.md](platforms/blog.md)

   If the destination folder already holds articles, read two of them: the author's own format outranks the platform file.

4. **Draft.** Write in the first person, with the author's concrete experience at the center. The author's habits, opinions and results go in only if they said so; everything else becomes a question in the final report. When adapting an existing article, rewrite it for the new format (angle, length, opening) and keep the facts.

5. **Style pass.** Call the Skill tool with `humanizer` on the draft and apply the result.

6. **Save.** One file per platform, at `<root>/<DD-MM-YYYY>/<slug>-<platform>.md`: today's date, a short topic slug, the platform (`linkedin`, `blog`, `medium`). The root is the folder the author names; otherwise use the current directory if it already has date folders, else ask.

7. **Report.** Give the path of each file and list what the author must check before publishing:
   - every claim about them that you inferred instead of hearing from them;
   - links that may not open for the public (claude.ai artifacts and repositories are private by default);
   - any number or quote you could not confirm in the source.
