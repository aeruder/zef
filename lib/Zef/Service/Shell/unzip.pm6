use Zef;

class Zef::Service::Shell::unzip does Extractor does Messenger {
    method extract-matcher($path) { so $path.IO.extension.lc eq 'zip' }

    method probe {
        state $probe = try { zrun('unzip', '--help', :!out, :!err).so };
    }

    method extract(IO() $archive-file, IO() $extract-to) {
        die "archive file does not exist: {$archive-file.absolute}"
            unless $archive-file.e && $archive-file.f;
        die "target extraction directory {$extract-to.absolute} does not exist and could not be created"
            unless ($extract-to.e && $extract-to.d) || mkdir($extract-to);

        my $passed;
        react {
            my $cwd := $archive-file.parent;
            my $ENV := %*ENV;
            my $proc = zrun-async('unzip', '-o', '-qq', $archive-file.basename, '-d', $extract-to.absolute);
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
            my $proc = zrun-async('unzip', '-Z', '-1', $archive-file.basename);
            whenever $proc.stdout { @extracted-paths.append(.lines) }
            whenever $proc.stderr { }
            whenever $proc.start(:$ENV, :$cwd) { $passed = $_.so }
        }

        $passed ?? @extracted-paths.grep(*.defined) !! ();
    }
}
