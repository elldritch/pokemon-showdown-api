toMessageType = (name) -> Symbol.for 'psc:' + name

MESSAGE_TYPES =
  OTHER:
    UNKNOWN: Symbol.for 'psc:unknown'

  ROOM_INIT:
    INIT: Symbol.for 'psc:init'
    USERLIST: Symbol.for 'psc:userlist'

  ROOM_MESSAGES:
    MESSAGE: Symbol.for 'psc:message'
    HTML: Symbol.for 'psc:html'
    JOIN: Symbol.for 'psc:join'
    LEAVE: Symbol.for 'psc:leave'
    NAME: Symbol.for 'psc:name'
    CHAT: Symbol.for 'psc:chat'
    TIMESTAMP: Symbol.for 'psc:timestamp'
    BATTLE: Symbol.for 'psc:battle'

  BATTLE:
    PLAYER: Symbol.for 'psc:player'
    GAMETYPE: Symbol.for 'psc:gametype'
    GEN: Symbol.for 'psc:gen'
    TIER: Symbol.for 'psc:tier'
    RATED: Symbol.for 'psc:rated'
    RULE: Symbol.for 'psc:rule'
    CLEARPOKE: Symbol.for 'psc:clearpoke'
    POKE: Symbol.for 'psc:poke'
    TEAMPREVIEW: Symbol.for 'psc:teampreview'
    REQUEST: Symbol.for 'psc:request'
    INACTIVE: Symbol.for 'psc:inactive'
    INACTIVEOFF: Symbol.for 'psc:inactiveoff'
    START: Symbol.for 'psc:start'
    WIN: Symbol.for 'psc:win'
    TIE: Symbol.for 'psc:tie'

    ACTIONS:
      MAJOR:
        MOVE: Symbol.for 'psc:move'
        SWITCH: Symbol.for 'psc:switch'
        SWAP: Symbol.for 'psc:swap'
        DETAILSCHANGE: Symbol.for 'psc:detailschange'
        CANT: Symbol.for 'psc:cant'
        FAINT: Symbol.for 'psc:faint'
      MINOR:
        FAIL: Symbol.for 'psc:-fail'
        DAMAGE: Symbol.for 'psc:-damage'
        HEAL: Symbol.for 'psc:-heal'
        STATUS: Symbol.for 'psc:-status'
        CURESTATUS: Symbol.for 'psc:-curestatus'
        CURETEAM: Symbol.for 'psc:-cureteam'
        BOOST: Symbol.for 'psc:-boost'
        UNBOOST: Symbol.for 'psc:-unboost'
        WEATHER: Symbol.for 'psc:-weather'
        FIELDSTART: Symbol.for 'psc:-fieldstart'
        FIELDEND: Symbol.for 'psc:-fieldend'
        SIDESTART: Symbol.for 'psc:-sidestart'
        SIDEEND: Symbol.for 'psc:-sideend'
        CRIT: Symbol.for 'psc:-crit'
        SUPEREFFECTIVE: Symbol.for 'psc:-supereffective'
        RESISTED: Symbol.for 'psc:-resisted'
        IMMUNE: Symbol.for 'psc:-immune'
        ITEM: Symbol.for 'psc:-item'
        ENDITEM: Symbol.for 'psc:-enditem'
        ABILITY: Symbol.for 'psc:-ability'
        ENDABILITY: Symbol.for 'psc:-endability'
        TRANSFORM: Symbol.for 'psc:-transform'
        MEGA: Symbol.for 'psc:-mega'
        ACTIVATE: Symbol.for 'psc:-activate'
        HINT: Symbol.for 'psc:-hint'
        CENTER: Symbol.for 'psc:-center'
        MESSAGE: Symbol.for 'psc:-message'
    ACTIONREQUESTS:
      TEAM: Symbol.for 'psc:team'
      MOVE: Symbol.for 'psc:move'
      SWITCH: Symbol.for 'psc:switch'
      CHOOSE: Symbol.for 'psc:choose'
      UNDO: Symbol.for 'psc:undo'

  GLOBAL:
    POPUP: Symbol.for 'psc:popup'
    PM: Symbol.for 'psc:pm'
    USERCOUNT: Symbol.for 'psc:usercount'
    NAMETAKEN: Symbol.for 'psc:nametaken'
    CHALLSTR: Symbol.for 'psc:challstr'
    UPDATEUSER: Symbol.for 'psc:updateuser'
    FORMATS: Symbol.for 'psc:formats'
    UPDATESEARCH: Symbol.for 'psc:updatesearch'
    UPDATECHALLENGES: Symbol.for 'psc:updatechallenges'
    QUERYRESPONSE: Symbol.for 'psc:queryresponse'

module.exports = {toMessageType, MESSAGE_TYPES}
