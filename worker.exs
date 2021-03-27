defmodule SecFilings.Worker do
    def main(args) do
        SecFilings.ParserWorker.start_link([])
    end
end
