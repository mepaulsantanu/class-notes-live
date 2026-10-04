# Case study: Class Notes Live

**Role:** Product owner, designer and builder (solo)
**Timeline:** September to October 2026
**Users:** Me and my MBA Marketing classmates (M5 section, CHRIST University, Bengaluru)

## The problem

My trimester runs five courses across about 20 hours of lectures a week. I wear a NeoSapien recorder, so every class is captured, but the output is a stream of short, unsorted recordings mixed with canteen chat, calls and group work. Turning that into something I can revise from took hours, and my classmates had no access to it at all.

Three pains stood out:

1. **Noise.** Of 371 recordings in the first three weeks, only 170 were real lectures for my five courses.
2. **Wrong format.** Machine minutes describe what was said. Exams test definitions, frameworks and examples.
3. **No sharing.** Notes lived in one person's app.

## Goal and success measures

Give the class one place where every lecture becomes exam-ready notes, without anyone doing manual work after class.

| Measure | Target |
| --- | --- |
| Lecture to published notes | Within minutes of next opening the laptop after class |
| Off-topic content on the site | Zero |
| Manual steps per class day | Zero |
| Coverage | Every recorded class day across five courses |

## Key product decisions

**1. Filter with the timetable, not with AI.**
My first version matched recordings to courses using keywords. It mis-sorted 16 lectures and let through social recordings. I switched to a rule anyone can audit: a recording belongs to a course only if it was made inside that course's timetable slot, has no social tags or words, and lasts more than 30 seconds. AI is used only after this gate.

**2. Clean before the AI sees anything.**
Off-topic sections (attendance, gossip, food, admin) are stripped from minutes in code. This keeps notes focused and reduces the personal data the model processes.

**3. Publish notes, never recordings.**
Recordings include faculty and classmates. Raw minutes stay on my laptop in a git-ignored folder. Only the finished notes go online. This was the condition for sharing with the class at all.

**4. A fixed note structure.**
Every class day follows the same template: overview, key terms table, Definition, Class example, Business example and Exam tip blocks, then practice questions. Consistency lets the site turn questions into flashcards and a quiz automatically, and makes notes easy to scan before an exam.

**5. Announcements stay human-approved.**
The system can spot deadlines in lectures, but a wrong date in green is worse than no date. Deadlines are posted by me only.

**6. Sync when the laptop wakes, not on a server.**
NeoSapien offers no public API, so a cloud server could not log in. Claude Code on my Mac can, through the same connector I already use. Instead of keeping the laptop on, the sync runs automatically whenever I open it and catches up on everything recorded while it was closed. Opening the laptop for a few minutes after class is enough, and the website itself stays online around the clock on GitHub Pages at no cost.

## What shipped

- Automated pipeline: fetch, filter, write notes, build, publish; runs on its own whenever the laptop wakes, with a 7-day catch-up
- Website with course tabs, class-day timeline, numbered notes with a table of contents, flashcards, quiz, search, timetable view and announcements with live countdowns
- 18 class days of notes at launch, with real business examples for every concept

## What I learned

- **Rules beat models for trust.** Classmates trust "recorded in the SBM slot" more than "the AI thinks it's SBM".
- **Privacy shapes scope.** Deciding early that raw audio never leaves my laptop made every later decision simpler.
- **The format is the product.** The biggest jump in usefulness came from the note template, not from more AI.

## Next

1. Move the sync to an always-on device once NeoSapien offers API access.
2. Suggested deadlines: the pipeline drafts announcements, I approve them in one tap.
3. Usage analytics to see which notes and flashcards classmates open most before exams.
