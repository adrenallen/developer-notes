<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;

class NotDisposableEmail implements ValidationRule
{
    /**
     * The list of blocked domains.
     *
     * @var array|null
     */
    protected static ?array $blockedDomains = null;

    /**
     * Load the blocked domains from the file.
     */
    protected function loadBlockedDomains(): void
    {
        if (is_null(self::$blockedDomains)) {
            $path = storage_path('disposable_email_blocklist.txt');
            if (!File::exists($path)) {
                Log::error("Disposable email blocklist file not found at {$path}");
                self::$blockedDomains = []; // Set to empty array if file not found
                return;
            }
            // Read file, trim whitespace, convert to lowercase, filter empty lines
            self::$blockedDomains = array_filter(array_map('strtolower', array_map('trim', File::lines($path)->toArray())));
        }
    }

    /**
     * Run the validation rule.
     *
     * @param  \Closure(string): \Illuminate\Translation\PotentiallyTranslatedString  $fail
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        $this->loadBlockedDomains();

        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            // Don't process invalid emails further
            return;
        }

        $domain = strtolower(substr(strrchr($value, "@"), 1));

        if (in_array($domain, self::$blockedDomains)) {
            $fail('The provided email address uses a disposable domain and is not permitted.');
        }
    }
}
