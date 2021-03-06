unit open_ldap;

{$LINKLIB ldap}

interface

{$include kent_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   unixtype;

// *************************************************************************
// * From lber_types.h
// *************************************************************************
type
   LBER_INT_T    = cint;
   uLBER_INT_T   = cuint;
   LBER_TAG_T    = clong;
   uLBER_TAG_T   = culong;
   LBER_SOCKET_T = cint;
   LBER_LEN_T    = clong;
   uLBER_LEN_T   = culong;
   ber_int_t     = LBER_INT_T;
   ber_sint_t    = LBER_INT_T;
   ber_uint_t    = uLBER_INT_T;
   ber_tag_t     = uLBER_TAG_T;
   ber_socket_t  = LBER_SOCKET_T;
   ber_len_t     = uLBER_LEN_T;
   ber_slen_t    = LBER_LEN_T;


// *************************************************************************
// * From lber.h
// *************************************************************************
type
   // structure for returning a sequence of octet strings + length
   berval = record
         bv_len:  ber_len_t;
         bv_val:  pchar;
      end; // berval record


// *************************************************************************
// * From ldap_features.h
// *************************************************************************
const
   LDAP_VENDOR_VERSION                     = 20130;
   LDAP_VENDOR_VERSION_MAJOR               = 2;
   LDAP_VENDOR_VERSION_MINOR               = 1;
   LDAP_VENDOR_VERSION_PATCH               = 30;
   // Is -lldap_r available or not
   LDAP_API_FEATURE_X_OPENLDAP_THREAD_SAFE = 1;
   // LDAP Server Side Sort.
   LDAP_API_FEATURE_SERVER_SIDE_SORT       = 1000;
   // LDAP Virtual List View.
   LDAP_API_FEATURE_VIRTUAL_LIST_VIEW      = 1000;


// *************************************************************************
// * From ldap.h
// *************************************************************************
const
   LDAP_VERSION1                   = 1;
   LDAP_VERSION2                   = 2;
   LDAP_VERSION3                   = 3;

   LDAP_VERSION_MIN                = LDAP_VERSION2;
  	LDAP_VERSION                    = LDAP_VERSION2;
   LDAP_VERSION_MAX                = LDAP_VERSION3;

   // We'll use 2000+draft revision for our API version number
   // As such, the number will be above the old RFC but below
   // whatever number does finally get assigned
   LDAP_API_VERSION                 = 2004;
   LDAP_VENDOR_NAME: ansistring     = 'OpenLDAP';

   // OpenLDAP API Features
   LDAP_API_FEATURE_X_OPENLDAP      = LDAP_VENDOR_VERSION;

   LDAP_API_FEATURE_THREAD_SAFE     = 1;
   LDAP_PORT                        = 389;  // ldap:///		default LDAP port
   LDAPS_PORT		                  = 636;  // ldaps:///	default LDAP over TLS port

   LDAP_ROOT_DSE: ansistring                    = '';
   LDAP_NO_ATTRS: ansistring                    = '1.1';
   LDAP_ALL_USER_ATTRIBUTES: ansistring         = '*';
   LDAP_ALL_OPERATIONAL_ATTRIBUTES: ansistring	= '+'; // OpenLDAP extension

   // LDAP_OPTions defined by draft-ldapext-ldap-c-api-02
   // $0000 - $0fff reserved for api options
   // $1000 - $3fff reserved for api extended options
   // $4000 - $7fff reserved for private and experimental options
   LDAP_OPT_API_INFO               = $0000;
   LDAP_OPT_DESC                   = $0001;  // deprecated
   LDAP_OPT_DEREF                  = $0002;
   LDAP_OPT_SIZELIMIT              = $0003;
   LDAP_OPT_TIMELIMIT              = $0004;
   // $05 - $07 not defined by current draft
   LDAP_OPT_REFERRALS              = $0008;
   LDAP_OPT_RESTART                = $0009;
   // $0a - $10 not defined by current draft
   LDAP_OPT_PROTOCOL_VERSION       = $0011;
   LDAP_OPT_SERVER_CONTROLS        = $0012;
   LDAP_OPT_CLIENT_CONTROLS        = $0013;
   // $14 not defined by current draft
   LDAP_OPT_API_FEATURE_INFO       = $0015;

   // $16 - $2f not defined by current draft
   LDAP_OPT_HOST_NAME              = $0030;
  	LDAP_OPT_ERROR_NUMBER           = $0031;
   LDAP_OPT_ERROR_STRING           = $0032;
   LDAP_OPT_MATCHED_DN             = $0033;

   // $34 - $0fff not defined by current draft

   LDAP_OPT_PRIVATE_EXTENSION_BASE = $4000;  // to $7FFF inclusive

   // private and experimental options
   // OpenLDAP specific options
   LDAP_OPT_DEBUG_LEVEL            = $5001;  // debug level
   LDAP_OPT_TIMEOUT                = $5002;  // default timeout
   LDAP_OPT_REFHOPLIMIT            = $5003;  // ref hop limit
   LDAP_OPT_NETWORK_TIMEOUT        = $5005;  // socket level timeout
   LDAP_OPT_URI                    = $5006;
   LDAP_OPT_REFERRAL_URLS          = $5007;  // Referral URLs

   // OpenLDAP TLS options
   LDAP_OPT_X_TLS                  = $6000;
   LDAP_OPT_X_TLS_CTX              = $6001;  // SSL CTX
   LDAP_OPT_X_TLS_CACERTFILE       = $6002;
   LDAP_OPT_X_TLS_CACERTDIR        = $6003;
   LDAP_OPT_X_TLS_CERTFILE         = $6004;
   LDAP_OPT_X_TLS_KEYFILE          = $6005;
   LDAP_OPT_X_TLS_REQUIRE_CERT     = $6006;
   // LDAP_OPT_X_TLS_PROTOCOL         = $6007
   LDAP_OPT_X_TLS_CIPHER_SUITE     = $6008;
   LDAP_OPT_X_TLS_RANDOM_FILE      = $6009;
   LDAP_OPT_X_TLS_SSL_CTX          = $600a;

   LDAP_OPT_X_TLS_NEVER            = 0;
   LDAP_OPT_X_TLS_HARD             = 1;
   LDAP_OPT_X_TLS_DEMAND           = 2;
   LDAP_OPT_X_TLS_ALLOW            = 3;
   LDAP_OPT_X_TLS_TRY              = 4;

   // OpenLDAP SASL options
   LDAP_OPT_X_SASL_MECH            = $6100;
   LDAP_OPT_X_SASL_REALM           = $6101;
   LDAP_OPT_X_SASL_AUTHCID         = $6102;
   LDAP_OPT_X_SASL_AUTHZID         = $6103;
   LDAP_OPT_X_SASL_SSF             = $6104;  // read-only
   LDAP_OPT_X_SASL_SSF_EXTERNAL    = $6105;  // write-only
   LDAP_OPT_X_SASL_SECPROPS        = $6106;  // write-only
   LDAP_OPT_X_SASL_SSF_MIN         = $6107;
   LDAP_OPT_X_SASL_SSF_MAX         = $6108;
  	LDAP_OPT_X_SASL_MAXBUFSIZE	     = $6109;

   // on/off values
   LDAP_OPT_ON		                 = pointer( 1);
   LDAP_OPT_OFF                    = pointer( 0);

   // ldap_get_option() and ldap_set_option() return values.
   // As later versions may return other values indicating
   // failure, current applications should only compare returned
   // value against LDAP_OPT_SUCCESS.
   LDAP_OPT_SUCCESS                = 0;
  	LDAP_OPT_ERROR                  = -1;



const  LDAP_API_INFO_VERSION = 1;
type
 ldapapiinfo = record
      ldapai_info_version:     cint;
      ldapai_api_version:      cint;
      ldapai_protocol_version: cint;
      ldapai_extensions:       ppchar;
      ldapai_vendor_name:      pchar;
      ldapai_vendor_version:   cint;
    end; //ldapapiinfo record


const  LDAP_FEATURE_INFO_VERSION = 1;
type ldap_apifeature_info = record
      ldapaif_info_version: cint;  // version of this struct (1)
	   ldapaif_name:         pchar; // matches LDAP_API_FEATURE_... less the prefix
	   ldapaif_version:      cint;  // matches the value LDAP_API_FEATURE_...
   end; //ldap_aipfeature_info record

type ldapcontrol = record
	   ldctl_oid:            pchar;
	   ldctl_value:          berval;
	   ldctl_iscritical:     byte;
   end;  // ldapcontrol record


const
   // LDAP Controls
   LDAP_CONTROL_VALUESRETURNFILTER     = '1.2.826.0.1.334810.2.3';
   LDAP_CONTROL_SUBENTRIES             = '1.3.6.1.4.1.4203.1.10.1';
   LDAP_CONTROL_NOOP                   = '1.3.6.1.4.1.4203.1.10.2';
   LDAP_CONTROL_MANAGEDSAIT            = '2.16.840.1.113730.3.4.2';
   LDAP_CONTROL_PROXY_AUTHZ            = '2.16.840.1.113730.3.4.18';

   LDAP_CONTROL_SORTREQUEST            = '1.2.840.113556.1.4.473';
   LDAP_CONTROL_SORTRESPONSE           = '1.2.840.113556.1.4.474';
   LDAP_CONTROL_VLVREQUEST             = '2.16.840.1.113730.3.4.9';
   LDAP_CONTROL_VLVRESPONSE            = '2.16.840.1.113730.3.4.10';


   // LDAP Unsolicited Notifications
  	LDAP_NOTICE_OF_DISCONNECTION        = '1.3.6.1.4.1.1466.20036';
   LDAP_NOTICE_DISCONNECT              = LDAP_NOTICE_OF_DISCONNECTION;


   // LDAP Extended Operations
   LDAP_EXOP_START_TLS                 = '1.3.6.1.4.1.1466.20037';

   LDAP_EXOP_MODIFY_PASSWD             = '1.3.6.1.4.1.4203.1.11.1';
   LDAP_TAG_EXOP_MODIFY_PASSWD_ID      = ber_tag_t( $80);
   LDAP_TAG_EXOP_MODIFY_PASSWD_OLD     = ber_tag_t( $81);
   LDAP_TAG_EXOP_MODIFY_PASSWD_NEW     = ber_tag_t( $82);
   LDAP_TAG_EXOP_MODIFY_PASSWD_GEN     = ber_tag_t( $80);

   LDAP_EXOP_X_WHO_AM_I                = '1.3.6.1.4.1.4203.1.11.3';


   // LDAP Features
   LDAP_FEATURE_ALL_OPERATIONAL_ATTRS  = '1.3.6.1.4.1.4203.1.5.1';  // +
   LDAP_FEATURE_OBJECTCLASS_ATTRS      = '1.3.6.1.4.1.4203.1.5.2';
   LDAP_FEATURE_ABSOLUTE_FILTERS       = '1.3.6.1.4.1.4203.1.5.3';  // (&) (|)
   LDAP_FEATURE_LANGUAGE_TAG_OPTIONS   = '1.3.6.1.4.1.4203.1.5.4';
   LDAP_FEATURE_LANGUAGE_RANGE_OPTIONS = '1.3.6.1.4.1.4203.1.5.5';

   // specific LDAP instantiations of BER types we know about
   // Overview of LBER tag construction
   //
   //	Bits
   //	______
   //	8 7 | CLASS
   //	0 0 = UNIVERSAL
   //	0 1 = APPLICATION
   //	1 0 = CONTEXT-SPECIFIC
   //	1 1 = PRIVATE
   //		_____
   //		| 6 | DATA-TYPE
   //		  0 = PRIMITIVE
   //		  1 = CONSTRUCTED
   //			___________
   //			| 5 ... 1 | TAG-NUMBER
   LDAP_TAG_MESSAGE          = ber_tag_t( $30);  // constructed + 16
   LDAP_TAG_MSGID            = ber_tag_t( $02);  // integer

   LDAP_TAG_LDAPDN           = ber_tag_t( $04);  // octet string
   LDAP_TAG_LDAPCRED         = ber_tag_t( $04);  // octet string

   LDAP_TAG_CONTROLS	        = ber_tag_t( $a0);  // context specific + constructed + 0
   LDAP_TAG_REFERRAL	        = ber_tag_t( $a3);  // context specific + constructed + 3

   LDAP_TAG_NEWSUPERIOR      = ber_tag_t( $80);  // context-specific + primitive + 0

   LDAP_TAG_EXOP_REQ_OID     = ber_tag_t( $80);  // context specific + primitive
   LDAP_TAG_EXOP_REQ_VALUE   = ber_tag_t( $81);  // context specific + primitive
   LDAP_TAG_EXOP_RES_OID     = ber_tag_t( $8a);  // context specific + primitive
   LDAP_TAG_EXOP_RES_VALUE   = ber_tag_t( $8b);  // context specific + primitive
   LDAP_TAG_SASL_RES_CREDS	  = ber_tag_t( $87);  // context specific + primitive


   // possible operations a client can invoke
   LDAP_REQ_BIND             = ber_tag_t( $60);  // application + constructed
   LDAP_REQ_UNBIND           = ber_tag_t( $42);  // application + primitive
   LDAP_REQ_SEARCH           = ber_tag_t( $63);  // application + constructed
   LDAP_REQ_MODIFY           = ber_tag_t( $66);  // application + constructed
   LDAP_REQ_ADD              = ber_tag_t( $68);  // application + constructed
   LDAP_REQ_DELETE           = ber_tag_t( $4a);  // application + primitive
   LDAP_REQ_MODDN            = ber_tag_t( $6c);  // application + constructed
   LDAP_REQ_MODRDN           = LDAP_REQ_MODDN;
   LDAP_REQ_RENAME           = LDAP_REQ_MODDN;
   LDAP_REQ_COMPARE          = ber_tag_t( $6e);  // application + constructed
   LDAP_REQ_ABANDON          = ber_tag_t( $50);  // application + primitive
   LDAP_REQ_EXTENDED         = ber_tag_t( $77);  // application + constructed

   // possible result types a server can return
   LDAP_RES_BIND             = ber_tag_t( $61);  // application + constructed
   LDAP_RES_SEARCH_ENTRY     = ber_tag_t( $64);  // application + constructed
   LDAP_RES_SEARCH_REFERENCE = ber_tag_t( $73);  // V3: application + constructed
   LDAP_RES_SEARCH_RESULT    = ber_tag_t( $65);  // application + constructed
   LDAP_RES_MODIFY           = ber_tag_t( $67);  // application + constructed
   LDAP_RES_ADD              = ber_tag_t( $69);  // application + constructed
   LDAP_RES_DELETE           = ber_tag_t( $6b);  // application + constructed
   LDAP_RES_MODDN            = ber_tag_t( $6d);  // application + constructed
   LDAP_RES_MODRDN           = LDAP_RES_MODDN;   // application + constructed
   LDAP_RES_RENAME           = LDAP_RES_MODDN;   // application + constructed
   LDAP_RES_COMPARE          = ber_tag_t( $6f);  // application + constructed
   LDAP_RES_EXTENDED	        = ber_tag_t( $78);  // V3: application + constructed
   LDAP_RES_EXTENDED_PARTIAL = ber_tag_t( $79);  // V3+: application + constructed

   LDAP_RES_ANY              = -1;
   LDAP_RES_UNSOLICITED      = 0;


   // sasl methods
   LDAP_SASL_EMPTY_STR:ansistring  = '';
   LDAP_SASL_SIMPLE          = pchar( 0);
 var
   LDAP_SASL_NULL: pchar;

const
   // authentication methods available
   LDAP_AUTH_NONE	           = ber_tag_t( $00);  // no authentication
   LDAP_AUTH_SIMPLE          = ber_tag_t( $80);  // context specific + primitive
   LDAP_AUTH_SASL            = ber_tag_t( $a3);  // context specific + constructed
   LDAP_AUTH_KRBV4           = ber_tag_t( $ff);  // means do both of the following
   LDAP_AUTH_KRBV41          = ber_tag_t( $81);  // context specific + primitive
   LDAP_AUTH_KRBV42          = ber_tag_t( $82);  // context specific + primitive


   // filter types
   LDAP_FILTER_AND           = ber_tag_t( $a0);  // context specific + constructed
   LDAP_FILTER_OR            = ber_tag_t( $a1);  // context specific + constructed
   LDAP_FILTER_NOT           = ber_tag_t( $a2);  // context specific + constructed
   LDAP_FILTER_EQUALITY	     = ber_tag_t( $a3);  // context specific + constructed
   LDAP_FILTER_SUBSTRINGS    = ber_tag_t( $a4);  // context specific + constructed
   LDAP_FILTER_GE            = ber_tag_t( $a5);  // context specific + constructed
   LDAP_FILTER_LE            = ber_tag_t( $a6);  // context specific + constructed
   LDAP_FILTER_PRESENT       = ber_tag_t( $87);  // context specific + primitive
   LDAP_FILTER_APPROX        = ber_tag_t( $a8);  // context specific + constructed
   LDAP_FILTER_EXT           = ber_tag_t( $a9);  // context specific + constructed

   // extended filter component types
   LDAP_FILTER_EXT_OID       = ber_tag_t( $81);  // context specific
   LDAP_FILTER_EXT_TYPE      = ber_tag_t( $82);  // context specific
   LDAP_FILTER_EXT_VALUE     = ber_tag_t( $83);  // context specific
   LDAP_FILTER_EXT_DNATTRS   = ber_tag_t( $84);  // context specific

   // substring filter component types
   LDAP_SUBSTRING_INITIAL    = ber_tag_t( $80);  // context specific
   LDAP_SUBSTRING_ANY        = ber_tag_t( $81);  // context specific
   LDAP_SUBSTRING_FINAL      = ber_tag_t( $82);  // context specific

   // search scopes
   LDAP_SCOPE_DEFAULT	     = ber_int_t( -1);
   LDAP_SCOPE_BASE		     = ber_int_t( $0000);
   LDAP_SCOPE_ONELEVEL	     = ber_int_t( $0001);
   LDAP_SCOPE_SUBTREE	     = ber_int_t( $0002);



   // possible error codes we can return
   LDAP_SUCCESS                  = $00;
   LDAP_OPERATIONS_ERROR         = $01;
   LDAP_PROTOCOL_ERROR           = $02;
   LDAP_TIMELIMIT_EXCEEDED       = $03;
   LDAP_SIZELIMIT_EXCEEDED       = $04;
   LDAP_COMPARE_FALSE            = $05;
   LDAP_COMPARE_TRUE             = $06;
   LDAP_AUTH_METHOD_NOT_SUPPORTED = $07;
   LDAP_STRONG_AUTH_NOT_SUPPORTED = LDAP_AUTH_METHOD_NOT_SUPPORTED;
   LDAP_STRONG_AUTH_REQUIRED     = $08;
   LDAP_PARTIAL_RESULTS          = $09;  // LDAPv2+ (not LDAPv3)

  	LDAP_REFERRAL                 = $0a; // LDAPv3
   LDAP_ADMINLIMIT_EXCEEDED      = $0b; // LDAPv3
  	LDAP_UNAVAILABLE_CRITICAL_EXTENSION = $0c; // LDAPv3
   LDAP_CONFIDENTIALITY_REQUIRED = $0d; // LDAPv3
  	LDAP_SASL_BIND_IN_PROGRESS    = $0e; // LDAPv3

   LDAP_NO_SUCH_ATTRIBUTE        = $10;
   LDAP_UNDEFINED_TYPE           = $11;
   LDAP_INAPPROPRIATE_MATCHING   = $12;
   LDAP_CONSTRAINT_VIOLATION     = $13;
   LDAP_TYPE_OR_VALUE_EXISTS     = $14;
   LDAP_INVALID_SYNTAX           = $15;

   LDAP_NO_SUCH_OBJECT           = $20;
   LDAP_ALIAS_PROBLEM            = $21;
   LDAP_INVALID_DN_SYNTAX        = $22;
   LDAP_IS_LEAF                  = $23; // not LDAPv3
   LDAP_ALIAS_DEREF_PROBLEM      = $24;

   LDAP_PROXY_AUTHZ_FAILURE      = $2F; // LDAPv3 proxy authorization
   LDAP_INAPPROPRIATE_AUTH       = $30;
   LDAP_INVALID_CREDENTIALS      = $31;
   LDAP_INSUFFICIENT_ACCESS      = $32;

   LDAP_BUSY                     = $33;
   LDAP_UNAVAILABLE              = $34;
   LDAP_UNWILLING_TO_PERFORM     = $35;
   LDAP_LOOP_DETECT              = $36;

   LDAP_NAMING_VIOLATION         = $40;
   LDAP_OBJECT_CLASS_VIOLATION   = $41;
   LDAP_NOT_ALLOWED_ON_NONLEAF   = $42;
   LDAP_NOT_ALLOWED_ON_RDN       = $43;
   LDAP_ALREADY_EXISTS           = $44;
   LDAP_NO_OBJECT_CLASS_MODS     = $45;
   LDAP_RESULTS_TOO_LARGE        = $46; // CLDAP
   LDAP_AFFECTS_MULTIPLE_DSAS    = $47; // LDAPv3

   LDAP_OTHER                    = $50;

   // reserved for APIs
   LDAP_SERVER_DOWN              = $51;
   LDAP_LOCAL_ERROR              = $52;
   LDAP_ENCODING_ERROR           = $53;
   LDAP_DECODING_ERROR           = $54;
   LDAP_TIMEOUT                  = $55;
   LDAP_AUTH_UNKNOWN             = $56;
   LDAP_FILTER_ERROR             = $57;
   LDAP_USER_CANCELLED           = $58;
   LDAP_PARAM_ERROR              = $59;
   LDAP_NO_MEMORY                = $5a;

   // used but not reserved for APIs
   LDAP_CONNECT_ERROR            = $5b;  // draft-ietf-ldap-c-api-xx
   LDAP_NOT_SUPPORTED            = $5c;  // draft-ietf-ldap-c-api-xx
   LDAP_CONTROL_NOT_FOUND        = $5d;  // draft-ietf-ldap-c-api-xx
   LDAP_NO_RESULTS_RETURNED      = $5e;  // draft-ietf-ldap-c-api-xx
   LDAP_MORE_RESULTS_TO_RETURN   = $5f;  // draft-ietf-ldap-c-api-xx
   LDAP_CLIENT_LOOP              = $60;  // draft-ietf-ldap-c-api-xx
   LDAP_REFERRAL_LIMIT_EXCEEDED  = $61;  // draft-ietf-ldap-c-api-xx

function LDAP_RANGE( n: word; x: word; y:word): boolean;
function LDAP_ATTR_ERROR( n: word): boolean;
function LDAP_NAME_ERROR( n: word): boolean;
function LDAP_SECURITY_ERROR( n: word): boolean;
function LDAP_SERVICE_ERROR( n: word): boolean;
function LDAP_UPDATE_ERROR( n: word): boolean;
function LDAP_API_ERROR( n: word): boolean;
function LDAP_API_RESULT( n: word): boolean;

   // This structure represents both ldap messages and ldap responses.
   // These are really the same, except in the case of search responses,
   // where a response has multiple messages.


type
   LDAPMessagePtr = pointer;
   LDAPPtr        = pointer;

function ldap_init( host: pchar; port: cint): LDAPptr; cdecl; external;
function ldap_simple_bind_s( ld: LDAPPtr; who: pchar; passwd: pchar): cint; cdecl; external;
function ldap_unbind_s( ld: LDAPPtr): cint; cdecl; external;



// ************************************************************************

implementation

// ************************************************************************

function LDAP_RANGE( n: word; x: word; y:word): boolean;
   begin
      result:= ((x <= n) and (n <= y));
   end; // LDAP_RANGE

// ************************************************************************

function LDAP_ATTR_ERROR( n: word): boolean;
   begin
      result:= LDAP_RANGE( n, $10, $15);
   end; // LDAP_RANGE


// ************************************************************************

function LDAP_NAME_ERROR( n: word): boolean;
   begin
      result:= LDAP_RANGE( n, $20, $24);
   end; // LDAP_RANGE


// ************************************************************************

function LDAP_SECURITY_ERROR( n: word): boolean;
   begin
      result:= LDAP_RANGE( n, $2f, $32);
   end; // LDAP_RANGE


// ************************************************************************

function LDAP_SERVICE_ERROR( n: word): boolean;
   begin
      result:= LDAP_RANGE( n, $33, $36);
   end; // LDAP_RANGE


// ************************************************************************

function LDAP_UPDATE_ERROR( n: word): boolean;
   begin
      result:= LDAP_RANGE( n, $40, $47);
   end; // LDAP_RANGE


// ************************************************************************

function LDAP_API_ERROR( n: word): boolean;
   begin
      result:= LDAP_RANGE( n, $51, $61);
   end; // LDAP_RANGE


// ************************************************************************

function LDAP_API_RESULT( n: word): boolean;
   begin
      result:= ((n = LDAP_SUCCESS) or LDAP_RANGE( n, $51, $61));
   end; // LDAP_RANGE


// ************************************************************************
// * Unit Initialization
// ************************************************************************
begin

//   LDAP_SASL_NULL:= @LDAP_SASL_EMPTY_STR[ 1];
end. // open_ldap unit
