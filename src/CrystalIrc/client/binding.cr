module CrystalIrc
  class Client
    # Default binding on the client.
    # Handles the classic behavior of a client.
    # ping, join, names, etc.
    module Binding
      def self.attach(obj)
        attach_chans(obj)
        attach_other(obj)
      end

      def self.attach_chans(obj)
        # Two cases: the client joins a chan or another user joins a chan
        obj.on("JOIN") do |msg|
          if msg.source_nick == obj.nick # the client joined
            chan = Chan.new(msg.arguments.first)
            obj.chans << chan
          else # someone else joined
            begin
              chan = obj.chan msg.arguments.first
              chan.as(Chan).users << User.new name
            rescue
              chan = Chan.new(msg.arguments.first)
              obj.chans << chan
            end
          end
        end

        obj.on("PART") do |msg|
          chan = obj.chan msg.arguments.first
          if msg.source_nick == obj.nick # the client left
            obj.chans.delete(chan)
          else # someone else left
            user = chan.as(Chan).users.bsearch { |e| e.name == name }
            chan.as(Chan).users.delete(user)
          end
        end

        obj.on("KICK") do |msg|
          name = msg.arguments[1]
          chan = obj.chan msg.arguments.first
          if name == obj.nick # the client just got kicked
            obj.chans.delete(chan)
          else # someone else has been kicked
            user = chan.as(Chan).users.bsearch { |e| e.name == name }
            chan.as(Chan).users.delete(user)
          end
        end

        self
      end

      def self.attach_other(obj)
        obj.on("PING") do |msg|
          msg.sender.pong(msg.message)
        end

        obj.on("353") do |msg|
          chan = obj.chan msg.arguments[2]
          chan.users = msg.arguments.last.split(" ").map do |name|
            User.new name.delete("@+")
          end
        end

        self
      end
      #
    end
  end
end
