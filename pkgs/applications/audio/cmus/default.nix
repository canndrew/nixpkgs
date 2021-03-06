{ stdenv, fetchFromGitHub, ncurses, pkgconfig

, alsaSupport ? stdenv.isLinux, alsaLib ? null
# simple fallback for everyone else
, aoSupport ? !stdenv.isLinux, libao ? null
, jackSupport ? false, libjack ? null
, samplerateSupport ? jackSupport, libsamplerate ? null
, ossSupport ? false, alsaOss ? null
, pulseaudioSupport ? false, libpulseaudio ? null

# TODO: add these
#, artsSupport
#, roarSupport
#, sndioSupport
#, sunSupport
#, waveoutSupport

, cddbSupport ? true, libcddb ? null
, cdioSupport ? true, libcdio ? null
, cueSupport ? true, libcue ? null
, discidSupport ? true, libdiscid ? null
, ffmpegSupport ? true, ffmpeg ? null
, flacSupport ? true, flac ? null
, madSupport ? true, libmad ? null
, mikmodSupport ? true, libmikmod ? null
, modplugSupport ? true, libmodplug ? null
, mpcSupport ? true, libmpcdec ? null
, tremorSupport ? false, tremor ? null
, vorbisSupport ? true, libvorbis ? null
, wavpackSupport ? true, wavpack ? null

# can't make these work, something is broken
#, aacSupport ? true, faac ? null
#, mp4Support ? true, mp4v2 ? null
#, opusSupport ? true, opusfile ? null

# not in nixpkgs
#, vtxSupport ? true, libayemu ? null
}:

with stdenv.lib;

assert samplerateSupport -> jackSupport;

# vorbis and tremor are mutually exclusive
assert vorbisSupport -> !tremorSupport;
assert tremorSupport -> !vorbisSupport;

let

  mkFlag = b: f: dep: if b
    then { flags = [ f ]; deps = [ dep ]; }
    else { flags = []; deps = []; };

  opts = [
    # Audio output
    (mkFlag alsaSupport       "CONFIG_ALSA=y"       alsaLib)
    (mkFlag aoSupport         "CONFIG_AO=y"         libao)
    (mkFlag jackSupport       "CONFIG_JACK=y"       libjack)
    (mkFlag samplerateSupport "CONFIG_SAMPLERATE=y" libsamplerate)
    (mkFlag ossSupport        "CONFIG_OSS=y"        alsaOss)
    (mkFlag pulseaudioSupport "CONFIG_PULSE=y"      libpulseaudio)

    #(mkFlag artsSupport      "CONFIG_ARTS=y")
    #(mkFlag roarSupport      "CONFIG_ROAR=y")
    #(mkFlag sndioSupport     "CONFIG_SNDIO=y")
    #(mkFlag sunSupport       "CONFIG_SUN=y")
    #(mkFlag waveoutSupport   "CONFIG_WAVEOUT=y")

    # Input file formats
    (mkFlag cddbSupport    "CONFIG_CDDB=y"    libcddb)
    (mkFlag cdioSupport    "CONFIG_CDIO=y"    libcdio)
    (mkFlag cueSupport     "CONFIG_CUE=y"     libcue)
    (mkFlag discidSupport  "CONFIG_DISCID=y"  libdiscid)
    (mkFlag ffmpegSupport  "CONFIG_FFMPEG=y"  ffmpeg)
    (mkFlag flacSupport    "CONFIG_FLAC=y"    flac)
    (mkFlag madSupport     "CONFIG_MAD=y"     libmad)
    (mkFlag mikmodSupport  "CONFIG_MIKMOD=y"  libmikmod)
    (mkFlag modplugSupport "CONFIG_MODPLUG=y" libmodplug)
    (mkFlag mpcSupport     "CONFIG_MPC=y"     libmpcdec)
    (mkFlag tremorSupport  "CONFIG_TREMOR=y"  tremor)
    (mkFlag vorbisSupport  "CONFIG_VORBIS=y"  libvorbis)
    (mkFlag wavpackSupport "CONFIG_WAVPACK=y" wavpack)

    #(mkFlag opusSupport   "CONFIG_OPUS=y"    opusfile)
    #(mkFlag mp4Support    "CONFIG_MP4=y"     mp4v2)
    #(mkFlag aacSupport    "CONFIG_AAC=y"     faac)

    #(mkFlag vtxSupport    "CONFIG_VTX=y"     libayemu)
  ];

in

stdenv.mkDerivation rec {
  name = "cmus-${version}";
  version = "2.7.1";

  src = fetchFromGitHub {
    owner  = "cmus";
    repo   = "cmus";
    rev    = "v${version}";
    sha256 = "0xd96py21bl869qlv1353zw7xsgq6v5s8szr0ldr63zj5fgc2ps5";
  };

  patches = [ ./option-debugging.patch ];

  configurePhase = "./configure " + concatStringsSep " " ([
    "prefix=$out"
    "CONFIG_WAV=y"
  ] ++ concatMap (a: a.flags) opts);

  buildInputs = [ ncurses pkgconfig ] ++ concatMap (a: a.deps) opts;

  meta = {
    description = "Small, fast and powerful console music player for Linux and *BSD";
    homepage = https://cmus.github.io/;
    license = stdenv.lib.licenses.gpl2;
    maintainers = [ stdenv.lib.maintainers.oxij ];
    platforms = stdenv.lib.platforms.linux;
  };
}
