local atom = require(script.Parent.Parent.atom)
local store = require(script.Parent.Parent.store)

return function()
	it("calls an atom without capturing it", function()
		local a, b, c = atom(1), atom(1), atom(1)
		local deps, result = store.capture(function()
			return a() + store.peek(b) + c()
		end)
		expect(deps[a]).to.be.ok()
		expect(deps[b]).to.never.be.ok()
		expect(deps[c]).to.be.ok()
		expect(result).to.equal(3)
	end)

	it("passes through arguments", function()
		expect(store.peek(1)).to.equal(1)
		expect(store.peek(function()
			return 1
		end)).to.equal(1)
	end)
end
