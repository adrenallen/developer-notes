# Laravel related dev notes

## Delayed Jobs
### Laravel's retry_after and Long-Running Jobs: Avoiding Duplicate Processing

Laravel's retry_after setting in config/queue.php (per connection) specifies how long a worker will wait before re-queueing a job that hasn't been completed or explicitly failed.

The Issue:

If retry_after is shorter than a job's actual processing time, the queue may re-queue the still-running job. This leads to multiple instances of the same job running concurrently, potentially causing "too many jobs" errors and resource exhaustion. For instance, a retry_after of 1 hour could cause a job taking slightly longer to be duplicated.

Solution: Dedicated Configuration for Long-Running Jobs

For jobs expected to run for extended periods:

Create a separate queue connection specifically for these long-running tasks.
Set a significantly higher retry_after value for this connection, appropriate for the maximum expected job duration, or configure it to minimize such retries.
Ensure the worker's timeout for this queue is also high, but critically, less than the retry_after value to prevent premature worker termination before a retry is legitimately considered.
This approach isolates long-running tasks, preventing unintended re-queues and ensuring stable job processing.


** IMPORTANT

in config/queue.php

retry_after  => If you hear nothing from the job (no success or failure) for x seconds, retry it.

in SomeJob.php

$retryAfter => If the job fails, retry it after x seconds.

