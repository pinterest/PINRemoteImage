source_pattern = /(\.m|\.mm|\.h)$/
  
# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
declared_trivial = github.pr_title.include? "#trivial"
has_changes_in_source_directory = !git.modified_files.grep(/Source/).empty?

modified_source_files = git.modified_files.grep(source_pattern)
has_modified_source_files = !modified_source_files.empty?
added_source_files = git.added_files.grep(source_pattern)
has_added_source_files = !added_source_files.empty?

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("This is a big PR, please consider splitting it up to ease code review.") if git.lines_of_code > 500

# Changelog entries are required for changes to source files.
no_changelog_entry = !git.modified_files.include?("CHANGELOG.md")
if has_changes_in_source_directory && no_changelog_entry && !declared_trivial
  warn("Any source code changes should have an entry in CHANGELOG.md or have #trivial in their title.")
end
