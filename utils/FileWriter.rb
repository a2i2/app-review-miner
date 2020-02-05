#!/usr/bin/ruby

# FileWriter is used to serially write line of string to a file.
class FileWriter
    def initialize
        @jobs = {}
        @threads = {}
    end

    # Wait for all threads to finish
    def wait_jobs
        @threads.each do |file_name, thread|
            thread.join
        end
    end

    def add_job(file_name, line)
        if file_name && line
            # Fetch the queue assigned for the specified file name
            queue = @jobs[file_name]

            # Create a new queue and thread to handle the queue
            if !queue
                queue = Queue.new
                @jobs[file_name] = queue

                # New thread to take jobs from the queue
                @threads[file_name] = Thread.new do
                    # Leave the file open until :terminate has been inserted to the queue
                    File.open(file_name, "w") do |file|
                        done = false
                        until done
                            # Wait for a job to enter
                            job = queue.pop
                            if job == :terminate
                                # :terminate symbol terminates the thread
                                done = true
                            else
                                # Write the string to file
                                file.write(job)
                            end
                        end
                    end

                    # Clean up
                    @threads.delete(file_name)
                    @jobs.delete(file_name)
                end
            end

            # Queue the specified line to be written
            queue << line
        end
    end
end
