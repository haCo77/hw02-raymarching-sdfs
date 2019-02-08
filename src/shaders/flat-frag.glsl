#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform float u_Time;
uniform vec4 u_Color;

in vec2 fs_Pos;
out vec4 out_Col;

#define MAX_STEPS 100
#define EPSILON 0.0001
#define SPEED 0.2

const vec3 LIGHTDIR1 = vec3(-0.6, -0.64, -0.48);
const vec3 LIGHTDIR2 = vec3(0.6, 0.48, 0.64);

const vec3 translateSeq[5] = vec3[5](vec3(0.0, 0.9, 0.0), vec3(0.0, 1.8, 0.0), 
                            vec3(0.0, 2.3, 0.0), vec3(0.0, 2.6, 0.0), vec3(0.0, 3.0, 0.0));
const vec3 scaleSeq[5] = vec3[5](vec3(1.2, 1.0, 1.2), vec3(1.66, 1.0, 1.66), 
                            vec3(1.52, 1.0, 1.52), vec3(1.14, 1.0, 1.14), vec3(0.75, 0.8, 0.75));

vec2 random2(vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(3.117, 1.271)), dot(p + seed, vec2(2.695, 1.833)))) * 853.545);
}

vec3 transform(vec3 pos, vec3 trans, vec3 scale, float degree) {
  float c = cos(degree * 3.1415926 / 180.0);
  float s = sin(degree * 3.1415926 / 180.0);
  mat2  m = mat2(c, -s, s, c);
  pos.xz = m * pos.xz;
  return (pos - trans) / scale;
}

float Sphere(vec3 p)
{
  return length(p) - 100.0;
}

float Moon(vec3 p) {
  float d = Sphere(p);
  float minusd = Sphere(transform(p, vec3(20.0, 0.0, -196.0), vec3(1.0), 0.0)); 
  d = max(d, -minusd);
  minusd = Sphere(transform(p, vec3(-70.0, -70.0, -170.0), vec3(1.0), 0.0)); 
  d = max(d, -minusd);
  minusd = Sphere(transform(p, vec3(-100.0, 40.0, -165.0), vec3(1.0), 0.0)); 
  d = max(d, -minusd);
  minusd = Sphere(transform(p, vec3(-160.0, -70.0, -90.0), vec3(1.0), 0.0)); 
  d = max(d, -minusd);
  minusd = Sphere(transform(p, vec3(-130.0, 130.0, -55.0), vec3(1.0), 0.0)); 
  d = max(d, -minusd);
  minusd = Sphere(transform(p, vec3(-130.0, 130.0, -55.0), vec3(1.0), 0.0)); 
  d = max(d, -minusd);
  minusd = Sphere(transform(p, vec3(60.0, -100.0, -160.0), vec3(1.0), 0.0)); 
  d = max(d, -minusd);
  minusd = Sphere(transform(p, vec3(0.0, 120.0, -155.0), vec3(1.0), 0.0)); 
  d = max(d, -minusd);
  return d;
}

float Box(vec3 p, vec3 b)
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

float boxBalloon(vec3 pos, vec3 trans, vec3 scale) {
  pos = transform(pos, trans, scale, 0.0);
  float current = Box(pos, vec3(0.2));
  float second = current;
  float new;
  for(int i = 0; i < 5; i++) {
    new = Box(transform(pos, translateSeq[i], scaleSeq[i], 0.0), vec3(0.5));
    if(new < current) {
      second = current;
      current = new;
    } else if(new < second) {
      second = new;
    }
  }
  float c = cos((pos.y + 0.06 * u_Time) * 3.1415926);
  float s = sin((pos.y + 0.06 * u_Time) * 3.1415926);
  mat2  m = mat2(c, -s, s, c);
  pos.xz -= vec2(0.1 * sqrt(abs(pos.y)));
  pos.xz = m * pos.xz;
  pos.xz += vec2(0.1 * sqrt(abs(pos.y)));
  pos.y += 4.5;
  pos.y -= clamp(pos.y, 0.0, 4.5);
  float d = length(pos) - 0.1;
  if(d < current)
    return d; 
  // return current;
  float h = clamp(0.5 + 0.5 * (current - second), 0.0, 1.0 );
  return mix(current, second, h) - h * (1.0 - h);
}

vec4 minDist(vec3 pos) {
  vec3 moonP = transform(pos, vec3(190.0, 50.0, 250.0), vec3(1.0), 0.0);
  
  vec2 cell = pos.xz;
  pos.xz = mod(pos.xz + vec2(10.0, -20.0), 20.0) - vec2(10.0, -20.0);
  cell = floor((cell - pos.xz + vec2(180.0, 0.0))/ 20.0) + 7.387;
  float u_Timenew = SPEED * u_Time;
  vec2 random = random2(vec2(floor(u_Timenew / 500.0), 317.49), cell * vec2(421.99, 777.321));
  random *= sqrt(length(random)) / length(random);
  float minD = boxBalloon(pos, vec3(random.x * 7.5, -50.0 + mod(u_Timenew * 0.2, 100.0) + length(random) * 10.0, 30.0 + random.y * 7.5), vec3(2.0));
  vec3 n = vec3(0.0);
  if(abs(minD) < EPSILON) {
    vec2 delta = vec2(-1.0, 1.0);
    n = delta.yyy * boxBalloon(pos + EPSILON * delta.yyy, vec3(random.x * 7.5, -50.0 + mod(u_Timenew * 0.2, 100.0) + length(random) * 10.0, 30.0 + random.y * 7.5), vec3(2.0))
            + delta.xyy * boxBalloon(pos + EPSILON * delta.xyy, vec3(random.x * 7.5, -50.0 + mod(u_Timenew * 0.2, 100.0) + length(random) * 10.0, 30.0 + random.y * 7.5), vec3(2.0))
            + delta.yxy * boxBalloon(pos + EPSILON * delta.yxy, vec3(random.x * 7.5, -50.0 + mod(u_Timenew * 0.2, 100.0) + length(random) * 10.0, 30.0 + random.y * 7.5), vec3(2.0))
            + delta.yyx * boxBalloon(pos + EPSILON * delta.yyx, vec3(random.x * 7.5, -50.0 + mod(u_Timenew * 0.2, 100.0) + length(random) * 10.0, 30.0 + random.y * 7.5), vec3(2.0));
    n = normalize(n);
  }

  float minD2 = Moon(moonP);
  if(minD < minD2) {
    return vec4(minD, n);
  }
  if(abs(minD2) < EPSILON) {
    vec2 delta = vec2(-1.0, 1.0);
    n = delta.yyy * Moon(moonP + EPSILON * delta.yyy)
            + delta.xyy * Moon(moonP + EPSILON * delta.xyy)
            + delta.yxy * Moon(moonP + EPSILON * delta.yxy)
            + delta.yyx * Moon(moonP + EPSILON * delta.yyx);
    n = normalize(n) + 1.3;
  }
  return vec4(minD2, n);
}

vec2 checkBoundingBox(vec2 xrange, vec2 yrange, vec2 zrange, vec3 ori, vec3 dir) {
  float t1, t2;
  float f1, f2;
  vec3 p1, p2;
  bool first = false;
  if(dir.z != 0.0) {
    t1 = (zrange.x - ori.z) / dir.z;
    t2 = (zrange.y - ori.z) / dir.z;
    if(t1 >= 0.0) {
      p1 = ori + t1 * dir;
      if(p1.x <= xrange.y && p1.x >= xrange.x && p1.y <= yrange.y && p1.y >= yrange.x) {
        first = true;
        f1 = t1;
      }
    }
    if(t2 >= 0.0) {
      p2 = ori + t2 * dir;
      if(p2.x <= xrange.y && p2.x >= xrange.x && p2.y <= yrange.y && p2.y >= yrange.x) {
        if(first) {
          return vec2(min(f1, t2), max(f1, t2));
        }
        else {
          first = true;
          f1 = t2;
        }
      }
    }
  }
  if(dir.y != 0.0) {
    t1 = (yrange.x - ori.y) / dir.y;
    t2 = (yrange.y - ori.y) / dir.y;
    if(t1 >= 0.0) {
      p1 = ori + t1 * dir;
      if(p1.x <= xrange.y && p1.x >= xrange.x && p1.z <= zrange.y && p1.z >= zrange.x) {
        if(first) {
          return vec2(min(f1, t1), max(f1, t1));
        } else {
          first = true;
          f1 = t1;
        }
      }
    }
    if(t2 >= 0.0) {
      p2 = ori + t2 * dir;
      if(p2.x <= xrange.y && p2.x >= xrange.x && p2.z <= zrange.y && p2.z >= zrange.x) {
        if(first) {
          return vec2(min(f1, t2), max(f1, t2));
        }
        else {
          first = true;
          f1 = t2;
        }
      }
    }
  }
  if(dir.x != 0.0) {
    t1 = (xrange.x - ori.x) / dir.x;
    t2 = (xrange.y - ori.x) / dir.x;
    if(t1 >= 0.0) {
      p1 = ori + t1 * dir;
      if(p1.y <= yrange.y && p1.y >= yrange.x && p1.z <= zrange.y && p1.z >= zrange.x) {
        if(first) {
          return vec2(min(f1, t1), max(f1, t1));
        } else {
          first = true;
          f1 = t1;
        }
      }
    }
    if(t2 >= 0.0) {
      p2 = ori + t2 * dir;
      if(p2.y <= yrange.y && p2.y >= yrange.x && p2.z <= zrange.y && p2.z >= zrange.x) {
        if(first) {
          return vec2(min(f1, t2), max(f1, t2));
        }
        else {
          return vec2(t2, t2);
        }
      }
    }
  }
  if(first)
    return vec2(f1, f1);
  return vec2(0.0, 0.0);
}

vec3 rayMarch(vec3 ori, vec3 dir) {
  vec2 trange = checkBoundingBox(vec2(-190.0, 290.0), vec2(-50.0, 150.0), vec2(25.0, 350.0), ori, dir);
  if(trange.x == 0.0 && trange.y == 0.0) {
    return vec3(0.0);
  }
  vec2 trange1 = checkBoundingBox(vec2(-190.0, 190.0), vec2(-50.0, 50.0), vec2(25.0, 150.0), ori, dir);
  vec2 trange2 = checkBoundingBox(vec2(90.0, 290.0), vec2(-50.0, 150.0), vec2(150.0, 350.0), ori, dir);
  float t, tmax;
  if(trange1.x == 0.0 && trange1.y == 0.0) {
    if(trange2.x == 0.0 && trange2.y == 0.0)
      return vec3(0.0);
    t = trange2.x;
    tmax = trange2.y; 
  } else {
    if(trange2.x == 0.0 && trange2.y == 0.0) {
      t = trange1.x;
      tmax = trange1.y; 
    } else {
      t = min(trange1.x, trange2.x);
      tmax = max(trange1.y, trange2.y);
    }
  }
  for(int i = 0; i < MAX_STEPS; i++) {
    if(t > tmax) {
      return vec3(0.0);
    }
    vec4 dn = minDist(ori + t * dir);
    if(abs(dn.x) < EPSILON) {
      return dn.yzw;
    }
    t += dn.x;
  }
  return vec3(0.0);
}

vec3 getDir(vec3 H, float len, vec2 coord) {
  return normalize(u_Ref - u_Eye + coord.x * H + coord.y * u_Up * len);
}

vec4 lambert(vec3 n, vec3 color) {
  return vec4(((max(dot(n, LIGHTDIR1), 0.0) + max(dot(n, LIGHTDIR2), 0.0)) + 0.1) * color, 1.0);
}

void main() {
  float len = length(u_Ref - u_Eye);
  vec3 H = normalize(cross(u_Ref - u_Eye, u_Up)) * len * u_Dimensions.x / u_Dimensions.y;
  vec2 delta = vec2(2.0 / u_Dimensions.x, 2.0 / u_Dimensions.y);

  //****** AA ****
  vec3 normal = rayMarch(u_Eye, getDir(H, len, fs_Pos - 0.25 * delta)) +
              rayMarch(u_Eye, getDir(H, len, fs_Pos + 0.25 * delta)) +
              rayMarch(u_Eye, getDir(H, len, fs_Pos + vec2(0.25, -0.25) * delta)) +
              rayMarch(u_Eye, getDir(H, len, fs_Pos + vec2(-0.25, 0.25) * delta));
  normal = normal / 4.0;
  
  // vec3 normal = rayMarch(u_Eye, getDir(H, len, fs_Pos));
  vec3 color;
  if(length(normal) > 1.0) {
    normal -= 1.3;
    switch(int(mod(floor(4.5 * normal.y + smoothstep(0.0, 2.0, 1.0 + sin(u_Time * 0.1))), 2.0)))
    {
      case 0:
        color = u_Color.xyz; 
        break;
      case 1:
        color = vec3(240.0, 168.0, 24.0) / 255.0;
        break;
      default:
        color = vec3(240.0, 168.0, 24.0) / 255.0;
    }
  } else {
    switch(int(mod(floor((normal.x / length(normal.xz) + normal.y) * 10.0 + 20.0), 5.0)))
    {
      case 0:
        color = vec3(0.0); //vec3(240.0, 168.0, 24.0) / 255.0;
        break;
      case 1:
        color = vec3(120.0, 144.0, 168.0) / 255.0;
        break;
      case 2:
        color = vec3(48.0, 72.0, 120.0) / 255.0;
        break;
      case 3:
        color = vec3(24.0, 24.0, 72.0) / 255.0;
        break;
      case 4:
        color = vec3(0.0, 0.0, 0.0);
        break;
      default:
        color = vec3(0.0, 0.0, 0.0);
    } 
  }
  out_Col = lambert(normal, color);
}
