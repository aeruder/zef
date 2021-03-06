use Zef;
use Zef::Service::Shell::PowerShell;

class Zef::Service::Shell::PowerShell::unzip is Zef::Service::Shell::PowerShell does Extractor does Messenger {
    method extract-matcher($path) { so $path.IO.extension.lc eq 'zip' }
    method probe { nextsame }

    method extract(IO() $archive-file, IO() $extract-to) {
        die "archive file does not exist: {$archive-file.absolute}"
            unless $archive-file.e && $archive-file.f;
        die "target extraction directory {$extract-to.absolute} does not exist and could not be created"
            unless ($extract-to.e && $extract-to.d) || mkdir($extract-to);

        my $passed;
        react {
            my $cwd := $archive-file.IO.parent;
            my $ENV := %*ENV;
            my $script := %?RESOURCES<scripts/win32unzip.ps1>.IO.absolute;
            my $proc = zrun-async(|@.ps-invocation, $script, $archive-file.basename, $extract-to.absolute);
            whenever $proc.stdout { }
            whenever $proc.stderr { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        my $extracted-to = $extract-to.child(self.list($archive-file).head);
        ($passed && $extracted-to.e) ?? $extracted-to !! False;
    }

    method list(IO() $archive-file) {
        die "archive file does not exist: {$archive-file.absolute}"
            unless $archive-file.e && $archive-file.f;

        my $passed;
        my @extracted-paths;
        react {
            my $cwd := $archive-file.parent;
            my $ENV := %*ENV;
            my $script := %?RESOURCES<scripts/win32unzip.ps1>.IO.absolute;
            my $proc = zrun-async(|@.ps-invocation, $script, $archive-file.basename);
            whenever $proc.stdout { @extracted-paths.append(.lines) }
            whenever $proc.stderr { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        $passed ?? @extracted-paths.grep(*.defined) !! ();
    }
}
