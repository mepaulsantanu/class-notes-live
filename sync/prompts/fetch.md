You are the fetch step of an automated sync job. Work silently and do not print recording content.

Task: save my recent NeoSapien recordings as files.

1. Call the NeoSapien tool search_memories with start_date "{{FROM}}", type "all", sort_order "asc", limit 100. If the result has more pages, fetch every page.
2. Use Glob on data/private/inbox/*.json to see which recording ids are already saved. Skip those.
3. For every new recording, call get_memory_by_id with include_mom true. Then use Write to save data/private/inbox/<_id>.json containing only this JSON object:
   {"_id": ..., "title": ..., "summary": ..., "domains": [...], "topics": [...], "started_at": ..., "finished_at": ..., "mom": ...}
   Copy the values exactly as returned. Do not edit, shorten or judge the content; filtering happens later in code.
4. Do not write any other files. Finish by replying with one line: DONE <number of new files>.
