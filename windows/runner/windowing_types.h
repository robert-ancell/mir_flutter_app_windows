#ifndef WINDOWING_TYPES_H_
#define WINDOWING_TYPES_H_

#include <cstdint>

namespace flw {

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

  enum class ConstraintAdjustment {
    none = 0,
    slide_x = 1,
    slide_y = 2,
    flip_x = 4,
    flip_y = 8,
    resize_x = 16,
    resize_y = 32
  };

  Rect anchor_rect;
  Anchor anchor;
  Gravity gravity;
  Offset offset;
  uint32_t constraint_adjustment;
};

} // namespace flw

#endif // WINDOWING_TYPES_H_
