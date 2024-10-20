package discord.user;

import discord.types.ConnectionState;
import discord.types.Colour;
import discord.utils.Utils;
import haxe.io.Bytes;
import discord.types.OneOfTwo;
import discord.types.IMessageable;
import discord.types.Types.Snowflake;

typedef PartialUserPayload = {
    var id:String;
    var username:String;
    var discriminator:String;
    @:optional var avatar:String;
    @:optional var global_name:String;
    @:optional var avatar_decoration_data:Dynamic; //TBD
}

typedef UserPayload = {
    >PartialUserPayload, // Inherit from PartialUserPayload
    var bot:Bool;
    var system:Bool;
    var mfa_enabled:Bool;
    var locale:String;
    var verified:Bool;
    @:optional var email:String;
    var flags:Int;
    var premium_type:Dynamic; //TBD
    var public_flags:Int; //TBD
}

class BaseUser extends Snowflake {
    public var name:String;
    public var discriminator:String;
    public var global_name:String;
    public var bot:Bool;
    public var system:Bool;
    private var _avatar:String = null;
    private var _banner:String = null;
    private var _accent_colour:Int = null;
    private var _public_flags:Int;

    private var _state:ConnectionState;

    /**
     * Returns the user's display name.
     * 
     * For regular users this is just their global name or their username,
     * but if they have a guild specific nickname then that
     * is returned instead.
     */
    public var display_name(get, never):String;

    /**
     * `PublicFlags`: The publicly available flags the user has.
     */
    public var public_flags(get, never):Dynamic; // TBD

    /**
     * `Asset`: Returns an `Asset` for the avatar the user has.
     * 
     * If the user has not uploaded a global avatar, `null` is returned.
     * 
     * If you want the avatar that a user has displayed, consider `display_avatar`.
     */
    public var avatar(get, never):Dynamic;

    /**
     * `Asset`: Returns the default avatar for a given user.
     */
    public var default_avatar(get, never):Dynamic;

    /**
     * `Asset`: Returns the user's display avatar.
     */
    public var display_avatar(get, never):Dynamic;

    private var _avatar_decoration_data:Dynamic; //TBD

    /**
     * `Asset`: Returns the avatar decoration the user has.
     * 
     * If the user has not set an avatar decoration, `null` is returned.
     */
    public var avatar_decoration(get, never):Dynamic;

    /**
     * Returns the SKU ID of the avatar decoration the user has.
     * 
     * If the user has not set an avatar decoration, `null` is returned.
     */
    public var avatar_decoration_sku_id(get, never):String;

    /**
     * A user's accent color is only shown if they do not have a banner.
     * This will only be available if the user explicitly sets a color.
     */
    public var accent_colour(get, never):Int;

    /**
     * A property that returns a colour denoting the rendered colour
     * for the user. This always returns 0xFF000000.
     */
    public var colour(get, never):Int;

    /**
     * Returns a string that allows you to mention the given user.
     */
    public var mention(get, never):String;

    /**
     * Returns the user's creation time in UTC.
     * This is when the user's Discord account was created.
     */
    public var created_at(get, never):Date;

    private var raw_data:Dynamic;
    private var payload:UserPayload;

    public function new(_state:ConnectionState, _payload:OneOfTwo<UserPayload, PartialUserPayload>, ?_raw_data:Dynamic) {
        this._state = _state;
        this.raw_data = _raw_data;
        this.payload = _payload;
        this._update(_payload, _raw_data);
    }

    private function _update(_payload:UserPayload, ?_raw_data:Dynamic) {
        // PartialUserPayload
        this.name = _payload.username;
        this.id = _payload.id;
        this.discriminator = _payload.discriminator;
        this.global_name = _payload.global_name;
        this._avatar = _payload.avatar;
        this._avatar_decoration_data = _payload.avatar_decoration_data ?? null;
        // UserPayload
        // _raw_data
        this._banner = _raw_data?.banner ?? null;
        this._accent_colour = _raw_data?.accent_color ?? null;
        // _payload
        this._public_flags = _payload.public_flags ?? 0;
        this.bot = _payload.bot ?? false;
        this.system = _payload.system ?? false;
    }

    /**
     * Return this user as a username
     * @return String
     */
    public function toString():String {
        if (this.discriminator == '0')
            return name;
        return '$name#$discriminator';
    }

    // Unfortunately, in order to override all the operators,
    // BaseUser must be an abstract. Thumbs down!

    public function _to_minimal_user_json() {
        return {
            'username': this.name,
            'id': this.id,
            'avatar': this._avatar,
            'discriminator': this.discriminator,
            'global_name': this.global_name,
            'bot': this.bot
        };
    }

    // TBD
    public function get_public_flags():Dynamic {
        return null;
    }

    public function get_avatar():Dynamic {
        return null;
    }

    public function get_default_avatar():Dynamic {
        return null;
    }

    public function get_display_avatar():Dynamic {
        return avatar ?? default_avatar;
    }

    public function get_avatar_decoration():Dynamic {
        return null;
    }

    public function get_avatar_decoration_sku_id():String {
        return _avatar_decoration_data?.sku_id ?? null;
    }

    public function get_accent_colour():Int {
        return new Colour(_accent_colour ?? 0);
    }

    public function get_colour():Int {
        return new Colour(0);        
    }

    public function get_mention():String {
        return '<@${this.id}>';
    }

    // TBD
    public function get_created_at():Date {
        return null;
    }

    public function get_display_name():String {
        return this.global_name ?? this.name;
    }
}

class ClientUser extends BaseUser {
    public var verified:Bool;
    public var locale:String;
    public var mfaEnabled:Bool;
    public var _flags:Int;

    public var mutual_guilds(get, never):Array<Dynamic>; // TBD
    // Guild

    public function new(_state:ConnectionState, _payload:UserPayload, _raw_data:Dynamic) {
        super(_state, _payload, _raw_data);
    }

    override public function _update(_payload:UserPayload, ?_raw_data:Dynamic) {
        super._update(_payload, _raw_data);

        this.verified = _payload.verified;
        this.locale = _payload.locale;
        this._flags = _payload.flags;
        this.mfaEnabled = _payload.mfa_enabled;
    }

    /**
     * Edits the current profile of the client.
     * 
     * To upload an avatar, a `Bytes` object must be passed in that
     * represents the image being uploaded.
     * 
     * @param username The new username you wish to change to.
     * @param avatar A `Bytes` object representing the image to upload. Could be `null` to denote no avatar. Only image formats supported for uploading are JPEG, PNG, GIF, and WEBP.
     * @param banner A `Bytes` object representing the image to upload. Could be `null` to denote no banner. Only image formats supported for uploading are JPEG, PNG, GIF, and WEBP.
     */
    public function edit(username:String, avatar:Bytes, banner:Bytes) {
        var _serialized_avatar = null;
        if (avatar != null)
            _serialized_avatar = Utils.bytesToBase64Data(avatar);

        var _serialized_banner = null;
        if (banner != null)
            _serialized_banner = Utils.bytesToBase64Data(banner);

        var data:Dynamic = {
            username: username,
            avatar: _serialized_avatar,
            banner: _serialized_banner
        }

        // TBD
    }

    override public function toString():String {
        return 'User(name=${name}, id=${id})';
    }

    // TBD
    public function get_mutual_guilds():Array<Dynamic> {
        return [null]; // _state.guilds
    }
}

class User extends BaseUser implements IMessageable {
    // TBD
    // DMChannel
    /**
     * Returns the channel associated with this user if it exists.
     * 
     * If this returns `null`, you can create a DM channel by calling the `create_dm` function.
     */
    public var dm_channel(get, never):Dynamic;

    /**
     * The guilds that the user shares with the client.
     * 
     * This will only return mutual guilds within the client's internal cache.
     */
    public var mutual_guilds(get, never):Array<Dynamic>; // TBD
    // Guild

    // TBD
    /**
     * Send a Direct Message to this user.
     * @param message 
     */
    public function send(message:String) { // Message
        return;
    }

    // DMChannel
    public function _get_channel():Dynamic {
        var ch = create_dm();
        return ch;
    }

    // TBD
    function get_dm_channel():Dynamic {
        // Note: return null from _get_private_channel_by_user if not found to trigger createDM correctly
        return null; // self._state._get_private_channel_by_user(self.id)
    }

    public function get_mutual_guilds():Array<Dynamic> {
        return [null, null]; // [guild for guild in self._state._guilds.values() if guild.get_member(self.id)]
    }

    // TBD
    public function create_dm():Dynamic {
        var found = this.dm_channel;
        if (found != null)
            return found;

        var state = _state;
        var data:Dynamic = null; // state.http.start_private_message(this.id); //DMChannelPayload
        return null; // state.add_dm_channel(data)
    }
}