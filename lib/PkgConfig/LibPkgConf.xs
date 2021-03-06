#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libpkgconf/libpkgconf.h>

static bool
my_error_handler(const char *msg, const pkgconf_client_t *client, const void *data)
{
  dSP;

  int count;
  bool value;
  const char *class;
    
  ENTER;
  SAVETMPS;
  
  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs((SV*)data);
  PUSHs(sv_2mortal(newSVpv(msg, 0)));
  PUTBACK;
  
  count = call_method("error", G_SCALAR);
  
  SPAGAIN;
  
  value = count > 0 && POPi;
  
  PUTBACK;
  FREETMPS;
  LEAVE;

  return value;
}

MODULE = PkgConfig::LibPkgConf  PACKAGE = PkgConfig::LibPkgConf::Client


void
_init(object, args)
    SV *object
    SV *args
  INIT:
    pkgconf_client_t *self;
  CODE:
    SvREFCNT_inc(object);
    self = pkgconf_client_new(my_error_handler, object);
    /* TODO: this should be optional */
    pkgconf_pkg_dir_list_build(self, 0);
    hv_store((HV*)SvRV(object), "ptr", 3, newSViv(PTR2IV(self)), 0);
    hv_store((HV*)SvRV(object), "sv",  2, newSViv(PTR2IV(object)), 0);


void
audit_set_log(object, filename, mode)
    SV *object
    const char *filename
    const char *mode
  INIT:
    pkgconf_client_t *self;
    FILE *fp;
  CODE:
    self = INT2PTR(pkgconf_client_t *, SvIV(*hv_fetch((HV*)SvRV(ST(0)), "ptr", 3, 0)));
    fp = fopen(filename, mode);
    pkgconf_audit_set_log(self, fp);
    hv_store((HV*)SvRV(object), "log", 3, newSViv(PTR2IV(fp)), 0);
    


const char *
sysroot_dir(self, ...)
    pkgconf_client_t *self
  CODE:
    if(items > 1)
    {
      pkgconf_client_set_sysroot_dir(self, SvPV_nolen(ST(1)));
    }
    RETVAL = pkgconf_client_get_sysroot_dir(self);
  OUTPUT:
    RETVAL


const char *
buildroot_dir(self, ...)
    pkgconf_client_t *self
  CODE:
    if(items > 1)
    {
      pkgconf_client_set_buildroot_dir(self, SvPV_nolen(ST(1)));
    }
    RETVAL = pkgconf_client_get_buildroot_dir(self);
  OUTPUT:
    RETVAL


void
DESTROY(...)
  INIT:
    pkgconf_client_t *self;
    SV *object;
    FILE *fp;
  CODE:
    if(hv_exists( (HV*) SvRV(ST(0)), "log", 3))
    {
      fp = INT2PTR(FILE *, SvIV(*hv_fetch((HV*)SvRV(ST(0)), "log", 3, 0)));
      fclose(fp);
    }
    self = INT2PTR(pkgconf_client_t *, SvIV(*hv_fetch((HV*)SvRV(ST(0)), "ptr", 3, 0)));
    object = INT2PTR(SV *, SvIV(*hv_fetch((HV*)SvRV(ST(0)), "sv", 2, 0)));
    pkgconf_client_free(self);
    SvREFCNT_dec(object);

IV
_find(self, name, flags)
    pkgconf_client_t *self
    const char *name
    unsigned int flags
  CODE:
    RETVAL = PTR2IV(pkgconf_pkg_find(self, name, flags));
  OUTPUT:
    RETVAL
    

MODULE = PkgConfig::LibPkgConf  PACKAGE = PkgConfig::LibPkgConf::Package

int
refcount(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->refcount;
  OUTPUT:
    RETVAL


const char *
id(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->id;
  OUTPUT:
    RETVAL


const char *
filename(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->filename;
  OUTPUT:
    RETVAL


const char *
realname(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->realname;
  OUTPUT:
    RETVAL


const char *
version(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->version;
  OUTPUT:
    RETVAL


const char *
description(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->description;
  OUTPUT:
    RETVAL


const char *
url(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->url;
  OUTPUT:
    RETVAL


const char *
pc_filedir(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->pc_filedir;
  OUTPUT:
    RETVAL


SV *
libs(self)
    pkgconf_pkg_t* self
  INIT:
    int len;
  CODE:
    len = pkgconf_fragment_render_len(&self->libs);
    RETVAL = newSV(len == 1 ? len : len-1);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, len-1);
    pkgconf_fragment_render_buf(&self->libs, SvPVX(RETVAL), len);
  OUTPUT:
    RETVAL


SV *
libs_private(self)
    pkgconf_pkg_t* self
  INIT:
    int len;
  CODE:
    len = pkgconf_fragment_render_len(&self->libs_private);
    RETVAL = newSV(len == 1 ? len : len-1);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, len-1);
    pkgconf_fragment_render_buf(&self->libs_private, SvPVX(RETVAL), len);
  OUTPUT:
    RETVAL


SV *
cflags(self)
    pkgconf_pkg_t* self
  INIT:
    int len;
  CODE:
    len = pkgconf_fragment_render_len(&self->cflags);
    RETVAL = newSV(len == 1 ? len : len-1);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, len-1);
    pkgconf_fragment_render_buf(&self->cflags, SvPVX(RETVAL), len);
  OUTPUT:
    RETVAL


SV *
cflags_private(self)
    pkgconf_pkg_t* self
  INIT:
    int len;
  CODE:
    len = pkgconf_fragment_render_len(&self->cflags_private);
    RETVAL = newSV(len == 1 ? len : len-1);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, len-1);
    pkgconf_fragment_render_buf(&self->cflags_private, SvPVX(RETVAL), len);
  OUTPUT:
    RETVAL


MODULE = PkgConfig::LibPkgConf  PACKAGE = PkgConfig::LibPkgConf::Util

void
argv_split(src)
    const char *src
  INIT:
    int argc, ret, i;
    char **argv;
  PPCODE:
    ret = pkgconf_argv_split(src, &argc, &argv);
    if(ret == 0)
    {
      for(i=0; i<argc; i++)
      {
        XPUSHs(sv_2mortal(newSVpv(argv[i],0)));
      }
      pkgconf_argv_free(argv);
    }
    else
    {
      croak("error in argv_split");
    }


int
compare_version(a,b)
    const char *a
    const char *b
  CODE:
    /* TODO: this isn't documented yet, so make sure   **
    **       that it is really part of the API before  **
    **       exposing it.                              **/
    RETVAL = pkgconf_compare_version(a,b);
  OUTPUT:
    RETVAL


MODULE = PkgConfig::LibPkgConf  PACKAGE = PkgConfig::LibPkgConf::Test


IV
send_error(client, msg)
    pkgconf_client_t *client
    const char *msg
  CODE:
    RETVAL = pkgconf_error(client, "%s", msg);
  OUTPUT:
    RETVAL
  
