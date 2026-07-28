# SUCCESS.md · the definition of properly wargamed

A wargame passes only when ALL eight hold.

1. Every move states its expected observation — exactly what you should see if the
   move worked.

2. Every move carries its most likely failure, the cause that failure signals, and
   the counter-move.

3. Every fork has a trigger. If you observe X, take route B. No judgment calls left
   to the executor.

4. Every assumption recon could not settle is marked `RECON NEEDED` with the exact
   check that settles it (a command to run, a file to read, a question to ask).

5. Abort conditions exist — the moments to stop and flag rather than improvise
   (missing credentials, a destructive operation with no confirmation path, a
   contradiction between the brief and what recon found).

6. Verification is spelled out: which commands/tests the executor runs, when, and
   what "pass" looks like for each one.

7. It has survived a red-team pass. The doc records the attack that failed against
   it (what could make this plan wrong or dangerous) and the patch born from that
   attack.

8. It is executable blind. A mid-tier model could run the mission end to end
   without asking a single clarifying question.
