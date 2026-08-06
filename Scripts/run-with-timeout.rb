#!/usr/bin/env ruby
# frozen_string_literal: true

timeout_seconds = Integer(ARGV.shift || abort("usage: run-with-timeout.rb SECONDS -- COMMAND [ARGS...]"))
separator = ARGV.shift
abort("usage: run-with-timeout.rb SECONDS -- COMMAND [ARGS...]") unless separator == "--" && ARGV.empty? == false

pid = Process.spawn(*ARGV)
deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout_seconds

loop do
  waited_pid, status = Process.waitpid2(pid, Process::WNOHANG)
  exit(status.exitstatus || 1) if waited_pid

  if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
    warn "Command timed out after #{timeout_seconds} seconds: #{ARGV.join(' ')}"
    begin
      Process.kill("TERM", pid)
    rescue Errno::ESRCH
      exit(124)
    end

    sleep 2
    begin
      Process.kill("KILL", pid)
    rescue Errno::ESRCH
      # The process exited after TERM.
    end
    Process.wait(pid)
    exit(124)
  end

  sleep 0.2
end
