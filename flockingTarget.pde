
class FlockingTarget
{
  PVector targetPos;
  float   targetRadius;
  float   targetStrength;
  
  FlockingTarget( PVector _targetPos, float _targetRadius, float _targetStrength )
  {
    targetPos      = _targetPos;
    targetRadius   = _targetRadius;
    targetStrength = _targetStrength;
  }
}
