Everything in here is Laravel related

# Delayed Jobs
## Dispatching jobs via artisan tinker

Requires calling Bus directly due to weirdness in how tinker handles dispatch facade

```php
Bus::dispatch(new Job())
```


## Laravel's retry_after and Long-Running Jobs: Avoiding Duplicate Processing

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

# Environment setup
## Sail alias shortcut w/Docker
For new setups you might not have sail yet so here's a docker copy paster
```bash
docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$(pwd):/var/www/html" \
    -w /var/www/html \
    laravelsail/php84-composer:latest \
    composer install --ignore-platform-reqs
```


# File Uploads
## Uploads not working with default storage facades

You need to link storage before it will work, sometimes this may not surface as an exception properly.

```bash
sail artisan storage:link
```
