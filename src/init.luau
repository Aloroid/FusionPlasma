--[[=[
	@class FusionPlasma
]=]]
local FusionPlasma = {}

local Packages = script.Parent

local Plasma = require(Packages.Plasma)
local Fusion = require(Packages.Fusion)

local Value = Fusion.Value

local exposed: (() -> unknown?)?
local applyParentTo: Instance?

--[[=[
	Wraps a component call into a new call compatible with Plasma
	
	@within FusionPlasma
	@param component (props: {[any]: any}) -- This is the component function which creates a Instance. It should have a props table as first argument.
	@param transformer (...unknown) -> ({[any]: any}, (() - ())?) -- This function transforms the props given and must returns a props table and can return a children function if neccesary.
	@param options {string}? -- Adds States to the props table for nillable properties.
	@return (...unknown) -> ...unknown -- A function used to create the given object. Arguments are from transformer, return value is from the exposed function.
]=]]
function FusionPlasma.wrap<T...>(component: (props: {[any]: any}) -> Instance, transformer: (T...) -> ({[any]: any}, (() -> ())?), options: {unknown}): (T...) -> unknown
	
	return Plasma.widget(function(...)
		
		local props, children = transformer(...)
		local valueProps, updateValueProps = Plasma.useState({})
		local callback: (() -> unknown)?, updateCallback = Plasma.useState()

		for _, key in options do
			if valueProps[key] and props[key] == nil then
				valueProps[key]:set(nil)
			else
				valueProps[key] = Value(nil)
			end
		end
		
		for key, value in props do
			if valueProps[key] then
				valueProps[key]:set(value)
			else
				valueProps[key] = Value(value)
			end
		end

		updateValueProps(valueProps)
		
		Plasma.useInstance(function()
			exposed, applyParentTo = nil, nil -- reset the values
			local inst = component(valueProps)
			
			-- We have to wrap this in a function as Plasma will call the
			-- function if the 
			updateCallback(function()
				return exposed
			end)
			callback = exposed
			
			return inst, applyParentTo
		end)
		
		local childrenCallback = children or function() end
		Plasma.scope(childrenCallback)
		
		if callback then
			return callback()
		else
			return nil
		end
	end)

end

--[[=[
	Used inside a component to expose a function to. This callback is ran
	everytime Plasma runs and is used to return a hook table with functions
	used to interact with the element, like checking if it's checked.
	This only functions inside a Component and is ignored otherwise.
	
	@within FusionPlasma
	@param callback (() -> unknown?) -- The function is used to return a hooks object.
]=]]
function FusionPlasma.expose(callback: (() -> unknown?))
	exposed = callback
end

--[[=[
	Used to parent objects from the children function into the given instance.
	Only one may be present per component.
	
	@within FusionPlasma
]=]]
FusionPlasma.ParentTo = {
	type = "SpecialKey",
	kind = "ParentTo",
	stage = "descendants",
	apply = function(self, value, applyTo)
		applyParentTo = applyTo
	end,
}

return FusionPlasma