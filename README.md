# control-panel.nvim

<img width="1602" alt="image" src="https://github.com/mhanberg/control-panel.nvim/assets/5523984/bded63bf-0ab1-435c-886a-8623b1dff02e">

```lua
{
  "mhanberg/control-panel.nvim",
  config = function()
    local cp = require("control_panel")
    cp.register {
      id = "output-panel",
      title = "Output Panel",
    }

    local handler = vim.lsp.handlers["window/logMessage"]

    vim.lsp.handlers["window/logMessage"] = function(err, result, context)
      handler(err, result, context)
      if not err then
        local client_id = context.client_id
        local client = vim.lsp.get_client_by_id(client_id)

        if not cp.panel("output-panel"):has_tab(client.name) then
          cp.panel("output-panel")
            :tab { name = client.name, key = tostring(#cp.panel("output-panel"):tabs() + 1) }
        end

        cp.panel("output-panel"):append {
          tab = client.name,
          text = "[" .. vim.lsp.protocol.MessageType[result.type] .. "] " .. result.message,
        }
      end
    end
  end,
}
```

## License

control-panel.nvim is MIT licensed unless otherwise noted.

`lua/control_panel/text/init.lua` is a modified version of source code extracted from https://github.com/folke/lazy.nvim from [this](https://github.com/folke/lazy.nvim/blob/652b6febf8d5c99eb8cf4a1cec63da6db62e77d2/lua/lazy/view/text.lua) point in time and is licensed with Apache 2.0.
