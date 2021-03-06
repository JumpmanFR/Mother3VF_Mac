#include "libups.hpp"
using namespace nall;

bool UPS::create(const char *x, const char *y, const char *z) {
  error = "";

    if(!fx.open(x, file::mode::read))  { error = "Impossible d’accéder au fichier d’entrée."; close(); return false; }
    if(!fy.open(y, file::mode::read))  { error = "Impossible d’accéder au fichier de sortie."; close(); return false; }
    if(!fz.open(z, file::mode::write)) { error = "Impossible d’accéder au fichier de patch.";    close(); return false; }
  crcx = crcy = crcz = ~0;

  //header
  zwrite('U');
  zwrite('P');
  zwrite('S');
  zwrite('1');
  encptr(fx.size());
  encptr(fy.size());

  //body
  uint64_t sizex = fx.size();
  uint64_t sizey = fy.size();
  uint64_t sizem = max(sizex, sizey);

  uint64_t relative = 0;
  for(uint64_t i = 0; i < sizem;) {
    uint8_t x = i < sizex ? xread() : 0x00;
    uint8_t y = i < sizey ? yread() : 0x00;

    if(x == y) {
      i++;
      continue;
    }

    encptr(i++ - relative);
    zwrite(x ^ y);

    for(;;) {
      if(i >= sizem) {
        zwrite(0x00);
        break;
      }

      x = i < sizex ? xread() : 0x00;
      y = y < sizey ? yread() : 0x00;
      i++;
      zwrite(x ^ y);
      if(x == y) break;
    }

    relative = i;
  }

  //footer
  for(unsigned i = 0; i < 4; i++) zwrite(~crcx >> (i << 3));
  for(unsigned i = 0; i < 4; i++) zwrite(~crcy >> (i << 3));
  fz.writel(~crcz, 4);

  close();
  return true;
}

bool UPS::apply(const char *x, const char *y, const char *z) {
  error = "";

    if(!fx.open(x, file::mode::read))      { error = "Impossible d’accéder au fichier d’entrée.";  close(); return false; }
    if(!fy.open(y, file::mode::writeread)) { error = "Impossible d’accéder au fichier de sortie."; close(); return false; }
    if(!fz.open(z, file::mode::read))      { error = "Impossible d’accéder au fichier de patch.";  close(); return false; }

  uint64_t sizez = fz.size();
  if(sizez < 20) { error = "Le fichier de patch n’est pas valide (inférieur à la taille attendue)."; close(); return false; }
  fz.seek(sizez - 12);
  uint32_t rcrcx = fz.readl(4);
  uint32_t rcrcy = fz.readl(4);
  uint32_t rcrcz = fz.readl(4);

  fz.seek(0);
  crcz = ~0;
  for(uint64_t i = 0; i < sizez - 4; i++) zread();
  if(~crcz != rcrcz) { error = "Le fichier de patch n’est pas valide (somme de contrôle CRC32 incorrecte).";  close(); return false; }
  fz.seek(0);

  if(zread() != 'U') { error = "Le fichier de patch n’est pas valide (en-tête incorrect)."; close(); return false; }
  if(zread() != 'P') { error = "Le fichier de patch n’est pas valide (en-tête incorrect)."; close(); return false; }
  if(zread() != 'S') { error = "Le fichier de patch n’est pas valide (en-tête incorrect)."; close(); return false; }
  if(zread() != '1') { error = "Le fichier de patch n’est pas valide (en-tête incorrect)."; close(); return false; }

  uint64_t sizex = decptr();
  uint64_t sizey = decptr();

  crcx = ~0;
  while(!fx.end()) xread();
  fx.seek(0);

  //in the special case that sizex == sizey && rcrcx == rcrcy,
  //no swap needs to be performed; checksum test will still work
  if(fx.size() == sizex && ~crcx == rcrcx) {
    //x^z->y
  } else if(fx.size() == sizey && ~crcx == rcrcy) {
    //y^z->x
      std::swap(sizex, sizey);
      std::swap(rcrcx, rcrcy);
  } else {
    error = "La taille ou la la somme de contrôle CRC32 du fichier d’entrée n’est pas valide. Cela signifie que vous n’avez pas sélectionné le fichier attendu.";
    close();
    return false;
  }

  for(uint64_t i = 0; i < sizex && i < sizey; i++) ywrite(xread());
  for(uint64_t i = sizex; i < sizey; i++) ywrite(0x00);
  fx.seek(0);
  fy.seek(0);

  uint64_t relative = 0;
  while(fz.offset() < sizez - 12) {
    relative += decptr();
    if(relative >= sizey) continue;

    fx.seek(relative);
    fy.seek(relative);
    for(uint64_t i = relative; i < sizey; i++) {
      uint8_t x = zread();
      relative++;
      if(!x) break;
      if(i < sizey) {
        uint8_t y = i < sizex ? xread() : 0x00;
        fy.write(x ^ y);
      }
    }
  }

  fy.seek(0);
  crcy = ~0;
  while(!fy.end()) yread();
  if(~crcy != rcrcy) { error = "La somme de contrôle CRC32 du fichier de sortie n’est pas valide."; close(); return false; }

  close();
  return true;
}

bool UPS::isAlreadyPatched(const char *x, const char *z) {

    if(!fx.open(x, file::mode::read))      { close(); return false; }
    if(!fz.open(z, file::mode::read))      { close(); return false; }

  uint64_t sizez = fz.size();
  if(sizez < 20) { close(); return false; }
  fz.seek(sizez - 12);
  uint32_t rcrcx = fz.readl(4);
  uint32_t rcrcy = fz.readl(4);
  uint32_t rcrcz = fz.readl(4);

  fz.seek(0);
  crcz = ~0;
  for(uint64_t i = 0; i < sizez - 4; i++) zread();
  if(~crcz != rcrcz) { close(); return false; }
  fz.seek(0);

  if(zread() != 'U') { close(); return false; }
  if(zread() != 'P') { close(); return false; }
  if(zread() != 'S') { close(); return false; }
  if(zread() != '1') { close(); return false; }

  uint64_t sizex = decptr();
  uint64_t sizey = decptr();

  crcx = ~0;
  while(!fx.end()) xread();
  fx.seek(0);

  //in the special case that sizex == sizey && rcrcx == rcrcy,
  //no swap needs to be performed; checksum test will still work
  if(fx.size() == sizex && ~crcx == rcrcx) {
    //x^z->y
    close();
    return false;
  } else if(fx.size() == sizey && ~crcx == rcrcy) {
    //y^z->x
    close();
    return true;
  } else {
    close();
    return false;
  }

}

//private:

void UPS::encptr(uint64_t offset) {
  for(;;) {
    uint64_t x = offset & 0x7f;
    offset >>= 7;
    if(offset == 0) {
      zwrite(0x80 | x);
      break;
    }
    zwrite(x);
    offset--;
  }
}

uint64_t UPS::decptr() {
  uint64_t offset = 0, shift = 1;
  for(;;) {
    uint8_t x = zread();
    offset += (x & 0x7f) * shift;
    if(x & 0x80) break;
    shift <<= 7;
    offset += shift;
  }
  return offset;
}

uint8_t UPS::xread() { uint8_t n = fx.read(); crcx = crc32_adjust(crcx, n); return n; }
uint8_t UPS::yread() { uint8_t n = fy.read(); crcy = crc32_adjust(crcy, n); return n; }
uint8_t UPS::zread() { uint8_t n = fz.read(); crcz = crc32_adjust(crcz, n); return n; }
void UPS::xwrite(uint8_t n) { fx.write(n); crcx = crc32_adjust(crcx, n); }
void UPS::ywrite(uint8_t n) { fy.write(n); crcy = crc32_adjust(crcy, n); }
void UPS::zwrite(uint8_t n) { fz.write(n); crcz = crc32_adjust(crcz, n); }

void UPS::close() {
  fx.close();
  fy.close();
  fz.close();
}

UPS::UPS() {
  error = "";
}

UPS::~UPS() {
  close();
}
