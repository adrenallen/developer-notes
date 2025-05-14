<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Symfony\Component\Process\Process;

class DevPreCommitChecks extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'dev:check';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Runs the pre-commit checks, linters, tests, etc';

    protected $checks = [
        'pint' => false,
        'npm-format' => false,
        'npm-lint' => false,
        'npm-build' => false,
        'tests' => false,
    ];

    protected $commands = [
        'pint' => 'vendor/bin/pint',
        'npm-format' => 'npm run format',
        'npm-lint' => 'npm run lint',
        'npm-build' => 'npm run build',
        'tests' => './vendor/bin/pest',
    ];

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Running pre-commit checks');

        foreach ($this->commands as $check => $command) {
            $this->newLine(2);
            $this->info("========== Running $check ==========");

            $env = $check === 'tests' ? ['APP_ENV' => 'testing'] : [];
            $successCallback = $this->getSuccessCallback($check);

            $this->runProcess(explode(' ', $command), $check, $successCallback, $env);
        }

        $this->displaySummary();

        return in_array(false, $this->checks) ? 1 : 0;
    }

    protected function runProcess(array $command, string $check, callable $successCallback, array $env = [], bool $tty = true): void
    {
        try {
            $process = new Process($command);
            $process->setTty($tty);

            if ($env) {
                $process->setEnv($env);
            }

            $output = '';
            $process->run(function ($type, $buffer) use (&$output) {
                $this->output->write($buffer);
                $output .= $buffer;
            });

            $this->checks[$check] = $successCallback($output, $process);
        } catch (\Exception $e) {
            if (str_contains($e->getMessage(), 'TTY') && $tty === true) {
                $this->info('TTY error, running without TTY');
                $this->runProcess($command, $check, $successCallback, $env, false);

                return;
            }

            $this->error("Failed to run $check: ".$e->getMessage());
            $this->checks[$check] = false;
        }
    }

    protected function getSuccessCallback(string $check): callable
    {
        return match ($check) {
            default => fn ($output, $process) => $process->isSuccessful()
        };
    }

    protected function displaySummary(): void
    {
        $this->newLine(2);
        $this->info('========== Completed pre-commit checks ==========');

        $this->newLine();
        $this->info('Summary Report:');
        foreach ($this->checks as $check => $passed) {
            $icon = $passed ? '<fg=green>✓</>' : '<fg=red>✗</>';
            $this->line("$icon $check");
        }

        $this->newLine();
        $this->comment('Please check messages above for any errors or warnings');
    }
}
