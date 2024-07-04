#ifndef MIR_WINDOWING_TYPES_H_
#define MIR_WINDOWING_TYPES_H_

#include <cstdint>

namespace mir {

enum class Archetype {
  regular,
  floating_regular,
  dialog,
  satellite,
  popup,
  tip
};

struct Size {
  int32_t width;
  int32_t height;
};

struct Rect {
  int32_t x;
  int32_t y;
  int32_t width;
  int32_t height;
};

struct Offset {
  int32_t dx;
  int32_t dy;
};

struct Positioner {
  enum class Anchor {
    none,
    top,
    bottom,
    left,
    right,
    top_left,
    bottom_left,
    top_right,
    bottom_right
  };

  enum class Gravity {
    none,
    top,
    bottom,
    left,
    right,
    top_left,
    bottom_left,
    top_right,
    bottom_right
  };

  Rect anchor_rect;
  Anchor anchor;
  Gravity gravity;
  Offset offset;
  uint32_t constraint_adjustment;
};

} // namespace mir

#endif // MIR_WINDOWING_TYPES_H_
