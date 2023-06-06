module FritzHome

using HTTP, LightXML, MD5, StringEncodings
using MbedTLS

struct FritzBox
    username::String
    password::String
    url::String
    session_id::Base.RefValue{String}
end

function FritzBox(username::String, password::String; url="https://fritz.box")
    return FritzBox(username, password, url, Base.RefValue(""))
end

function command_url(fritz::FritzBox, command::String; args...)
    args = [:switchcmd => command, :sid => session_id!(fritz), args...]
    base = "$(fritz.url)/webservices/homeautoswitch.lua?"
    return base * join(map(((k, v),)-> "$k=$v", args), "&")
end

function parse_response(response)
    if response.status != 200
        error("Response not good: $(response)")
    end
    type = Dict(response.headers)["Content-Type"]
    body = String(response.body)
    if startswith(type, "text/plain")
        return chomp(body)
    elseif startswith(type, "text/xml")
        return root(LightXML.parse_string(body))
    else
        error("Type $(type) unknown")
    end
end

function execute(fritz, command; args...)
    url = command_url(fritz, command; args...)
    response = HTTP.get(url, require_ssl_verification=false, status_exception=false)
    if response.status == 403
        # our session went out of fashion
        # login & try again...
        @info("Session run out, login in again")
        login!(fritz)
        url = command_url(fritz, command; args...)
        # This time we error though, since there's not much left to do if this fails!
        response = HTTP.get(url, require_ssl_verification=false)
    end
    return parse_response(response)
end

function get_parsed(url)
    response = HTTP.get(url, require_ssl_verification=false, status_exception=false)
    return parse_response(response)
end

getelement(doc, name) = content(find_element(doc, name))

function to_challenge(challenge, password)
    utf = encode(challenge * "-" * password, "UTF-16LE")
    return challenge * "-" * bytes2hex(md5(utf))
end

function session_id!(fritz::FritzBox)
    if isempty(fritz.session_id[])
        login!(fritz)
    end
    return fritz.session_id[]
end

function login!(fritz::FritzBox)
    login_url = "$(fritz.url)/login_sid.lua"
    doc = get_parsed(login_url)
    sid = getelement(doc, "SID")
    if sid == "0000000000000000"
        # are you challenging me!?
        challenge = getelement(doc, "Challenge")
        response = to_challenge(challenge, fritz.password)
        uri = "$(login_url)?username=" * fritz.username * "&response=" * response
        doc = get_parsed(uri)
        sid = getelement(doc, "SID")
        if sid === "0000000000000000"
            error("Could not login")
        end
    end
    fritz.session_id[] = sid
    return fritz
end

function to_dict(node::XMLNode)
    result = []
    dict = Dict{String, Any}()
    for elem in child_nodes(node)
        if elem isa XMLNode
            elems = collect(child_nodes(elem))
            if length(elems) > 1
                dict[name(elem)] = to_dict(elem)
            else
                dict[name(elem)] = content(elem)
            end
        else
            push!(result, elem)
        end
    end
    !isempty(dict) && return dict
    length(result) == 1 && return result[1]
    return result
end

function to_device(device_xml)
    attributes = attributes_dict(XMLElement(device_xml))
    additional_attributes = to_dict(device_xml)
    return merge(attributes, additional_attributes)
end

device_id(dev) = dev["identifier"]

function devices(fritz::FritzBox)
    devices = execute(fritz, "getdevicelistinfos")
    return to_device.(child_nodes(devices))
end

function to_temperature(response)
    return parse(Float64, response) * 0.5
end

function temperature(fritz, device)
    response = execute(fritz, "gettemperature", ain=device_id(device))
    return parse(Float64, response) / 10
end

function goal_temperature(fritz, device)
    response = execute(fritz, "gethkrtsoll", ain=device_id(device))
    return parse(Float64, response) * 0.5
end

function set_goal_temperature!(fritz, device, temperature)
    temperature =  16 + ( ( temperature - 8 ) * 2 )
    response = execute(fritz, "sethkrtsoll", ain=device_id(device), param=temperature)
    return to_temperature(response)
end

end # module
