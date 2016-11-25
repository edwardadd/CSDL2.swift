require 'fileutils'

PATH = ARGV[0]

BLACKLIST_FILES = [/SDL_test/, /opengles/]
BLACKLIST_DEFS = [/WINRT/]

includes = []

if RUBY_PLATFORM =~ /linux/
  includes += ["GL/gl.h", "GL/glu.h"]
end

# always include main SDL header first
includes << "SDL2/SDL.h"

defs = %w(
  WINDOWPOS_UNDEFINED
  WINDOWPOS_CENTERED
)

Dir.chdir(PATH) do
  Dir["SDL2/SDL*.h"].each do |file|
    next if BLACKLIST_FILES.any? { |b| file =~ b }
    includes << file
    state = :out
    File.open(file).each_line do |line|
      case state
      when :out
        state = :in if line =~ /typedef\s+enum/
      when :in
        if line =~ /\}/
          state = :out
        elsif line =~ /^\s*SDL_(\w+)/
          defs << $1
        end
      end
    end
  end
end

defs = defs.reject { |d| BLACKLIST_DEFS.any? { |b| d =~ b } }

puts includes.map { |i| "#include <#{i}>" }.join("\n")
puts "int main() {\n"
puts defs.map { |d| "    printf(\"#define K_SDL_#{d} 0x%08x\\n\", SDL_#{d});" }
puts "    return 0;\n"
puts "}\n"