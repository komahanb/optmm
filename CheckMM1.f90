program CheckMM1

implicit none

      integer n
      parameter(n=3)
      double precision  x(n), obj, c(n), rho, L, sigmay, pi, Fs, p, E
      double precision sigmax(n),fMM1,objgrad(n),cMM1(n),dc(n,n)
      double precision fmean,fvar,cmean(n),cstd(n)
      double precision Varf,Varc(n)
      integer kprob,j,NMC,nm,seed

      double precision :: Dsave(n,1000000),dinvnorm

      !deterministic optimization
      !x(1)=0.731287610198794        
      !x(2)=1.26662779095808        
      !x(3)=7.07107202636674
      ! W=4.14786577726155e+00

      !x(1:3)=2.0

      ! MM1 optimization
      x(1)=0.859123529676287
      x(2)=1.21912282279619
      x(3)=6.12354191150525
      ! obj=
      ! W=3.95152855545012 

      ! Kriging optimization
      !x(1)=0.895167323327774        
      !x(2)=1.24244679330450        
      !x(3)=6.18642565355657     
      ! obj= 4.23276576252132
      ! W=4.07223888221433

    

      sigmax(1)=0.15
      sigmax(2)=0.15
      sigmax(3)=0.1

      kprob=3

!--------------
! Monte-Carlo |
!--------------

      NMC=1000000

      call get_seed(seed)
      call latin_random(n,NMC,seed,Dsave)
          
      fmean=0.0
      fvar=0.0
      cmean(:)=0.0
      cstd(:)=0.0
      do nm = 1, NMC
         do j=1,n 
            Dsave(j,nm)=x(j)+dinvnorm(Dsave(j,nm))*sigmax(j)
         end do
         call compute_fc (Dsave(:,nm), obj, c, n)
         fmean=fmean+obj
         fvar=fvar+obj**2
         cmean(:)=cmean(:)+c(:)
         cstd(:)=cstd(:)+c(:)**2
      end do

      fmean=fmean/real(NMC)      
      fvar=fvar/real(NMC)-fmean**2
      cmean(:)=cmean(:)/real(NMC)
      cstd(:)=cstd(:)/real(NMC)-cmean(:)**2
      cstd(:)=sqrt(cstd(:))


      obj=fmean+fvar
      c(:)=cmean(:)+kprob*cstd(:)
      
      print *,'Monte-Carlo',fmean,fvar,c(1:n)




!--------------
! MM1         |
!--------------

      rho=0.2836
      sigmay=36260.0
      p=25000.0
      L=5.0
      Fs=1.0
      E=30e6
      pi=4.0*atan(1.0)

   
!---- MEAN OF OBJECTIVE FUNCTION

      fMM1 = rho*x(1)*L+rho*x(2)*sqrt(L**2+x(3)**2)

!---- GRADIENT OF OBJECTIVE FUNCTION
      objgrad(1) = rho*L
      objgrad(2) = rho*sqrt(L**2+x(3)**2)
      objgrad(3) = rho*x(2)*x(3) / sqrt(L**2+x(3)**2)

      Varf=0.0
      do j=1,3
         Varf=Varf+(objgrad(j)*sigmax(j))**2
      end do

!---- COMBINED OBJECTIVE FUNCTION

      fMM1=fMM1!+Varf


!---- MEAN OF INEQUALITY CONSTRAINTS
      cMM1(1) = p*Fs*sqrt(L**2+x(3)**2) / (x(2)*x(3)*sigmay) - 1.0
      cMM1(2) = p*Fs*L / (x(1)*x(3)*sigmay) - 1.0
      cMM1(3) = 4.0*p*Fs*L**3 / (x(1)**2*x(3)*E*pi) - 1.0

!---- GRADIENT OF CONSTRAINTS

      dc(:,:)=0.0

      dc(1,2) = -p*Fs*sqrt(L**2+x(3)**2) / (x(2)**2*x(3)*sigmay)
      dc(1,3) = -p*Fs*L**2/sqrt(L**2/x(3)**2+1.0)/ (x(2)*x(3)**3*sigmay)

      dc(2,1) = -p*Fs*L / (x(1)**2*x(3)*sigmay)
      dc(2,3) = -p*Fs*L / (x(1)*x(3)**2*sigmay)

      dc(3,1) = -8.0*p*Fs*L**3 / (pi*E*x(1)**3*x(3))
      dc(3,3) = -4.0*p*Fs*L**3 / (pi*E*x(1)**2*x(3)**2)

      Varc(:)=0.0
      do j=1,3
         Varc(:)=Varc(:)+(dc(:,j)*sigmax(j))**2
      end do

!---- COMBINED INEQUALITY CONSTRAINTS

      cMM1(1:n)=cMM1(1:n)+kprob*sqrt(Varc(1:n))

      print *,'MM1',fMM1,Varf,cMM1(1:n)


end program CheckMM1


subroutine compute_fc (x, obj, c, n)

      implicit none

      double precision  x(*), obj, c(*), rho, L, sigmay, pi, Fs, p, E
      integer n

      rho=0.2836
      sigmay=36260.0
      p=25000.0
      L=5.0
      Fs=1.0
      E=30e6
      pi=4.0*atan(1.0)


!---- OBJECTIVE FUNCTION

      obj = rho*x(1)*L+rho*x(2)*sqrt(L**2+x(3)**2)


!---- INEQUALITY CONSTRAINTS
      c(1) = p*Fs*sqrt(L**2+x(3)**2) / (x(2)*x(3)*sigmay) - 1.0
      c(2) = p*Fs*L / (x(1)*x(3)*sigmay) - 1.0
      c(3) = 4.0*p*Fs*L**3 / (x(1)**2*x(3)*E*pi) - 1.0

      return 
      end



subroutine get_seed ( seed )

!*****************************************************************************80
!
!! GET_SEED returns a seed for the random number generator.
!
!  Discussion:
!
!    The seed depends on the current time, and ought to be (slightly)
!    different every millisecond.  Once the seed is obtained, a random
!    number generator should be called a few times to further process
!    the seed.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license.
!
!  Modified:
!
!    02 August 2004
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Output, integer ( kind = 4 ) SEED, a pseudorandom seed value.
!
  implicit none

  integer   ( kind = 4 ) seed
  real      ( kind = 8 ) temp
  character ( len = 10 ) time
  character ( len = 8 )  today
  integer   ( kind = 4 ) values(8)
  character ( len = 5 )  zone

  call date_and_time ( today, time, zone, values )

  temp = 0.0D+00

  temp = temp + real ( values(2) - 1, kind = 8 ) /  11.0D+00
  temp = temp + real ( values(3) - 1, kind = 8 ) /  30.0D+00
  temp = temp + real ( values(5),     kind = 8 ) /  23.0D+00
  temp = temp + real ( values(6),     kind = 8 ) /  59.0D+00
  temp = temp + real ( values(7),     kind = 8 ) /  59.0D+00
  temp = temp + real ( values(8),     kind = 8 ) / 999.0D+00
  temp = temp                                    /   6.0D+00

  do while ( temp <= 0.0D+00 )
    temp = temp + 1.0D+00
  end do

  do while ( 1.0D+00 < temp )
    temp = temp - 1.0D+00
  end do

  seed = int ( real ( huge ( 1 ), kind = 8 ) * temp )
!
!  Never use a seed of 0 or maximum integer ( kind = 4 ).
!
  if ( seed == 0 ) then
    seed = 1
  end if

  if ( seed == huge ( 1 ) ) then
    seed = seed - 1
  end if

  return
end subroutine get_seed


function i4_uniform ( a, b, seed )

!*****************************************************************************80
!
!! I4_UNIFORM returns a scaled pseudorandom I4.
!
!  Discussion:
!
!    An I4 is an integer ( kind = 4 ) value.
!
!    The pseudorandom number will be scaled to be uniformly distributed
!    between A and B.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    31 May 2007
!
!  Author:
!
!    John Burkardt
!
!  Reference:
!
!    Paul Bratley, Bennett Fox, Linus Schrage,
!    A Guide to Simulation,
!    Second Edition,
!    Springer, 1987,
!    ISBN: 0387964673,
!    LC: QA76.9.C65.B73.
!
!    Bennett Fox,
!    Algorithm 647:
!    Implementation and Relative Efficiency of Quasirandom
!    Sequence Generators,
!    ACM Transactions on Mathematical Software,
!    Volume 12, Number 4, December 1986, pages 362-376.
!
!    Pierre L'Ecuyer,
!    Random Number Generation,
!    in Handbook of Simulation,
!    edited by Jerry Banks,
!    Wiley, 1998,
!    ISBN: 0471134031,
!    LC: T57.62.H37.
!
!    Peter Lewis, Allen Goodman, James Miller,
!    A Pseudo-Random Number Generator for the System/360,
!    IBM Systems Journal,
!    Volume 8, Number 2, 1969, pages 136-143.
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) A, B, the limits of the interval.
!
!    Input/output, integer ( kind = 4 ) SEED, the "seed" value, which
!    should NOT be 0.  On output, SEED has been updated.
!
!    Output, integer ( kind = 4 ) I4_UNIFORM, a number between A and B.
!
  implicit none

  integer ( kind = 4 ) a
  integer ( kind = 4 ) b
  integer ( kind = 4 ), parameter :: i4_huge = 2147483647
  integer ( kind = 4 ) i4_uniform
  integer ( kind = 4 ) k
  real    ( kind = 4 ) r
  integer ( kind = 4 ) seed
  integer ( kind = 4 ) value

  if ( seed == 0 ) then
    write ( *, '(a)' ) ' '
    write ( *, '(a)' ) 'I4_UNIFORM - Fatal error!'
    write ( *, '(a)' ) '  Input value of SEED = 0.'
    stop
  end if

  k = seed / 127773

  seed = 16807 * ( seed - k * 127773 ) - k * 2836

  if ( seed < 0 ) then
    seed = seed + i4_huge
  end if

  r = real ( seed, kind = 4 ) * 4.656612875E-10
!
!  Scale R to lie between A-0.5 and B+0.5.
!
  r = ( 1.0E+00 - r ) * ( real ( min ( a, b ), kind = 4 ) - 0.5E+00 ) & 
    +             r   * ( real ( max ( a, b ), kind = 4 ) + 0.5E+00 )
!
!  Use rounding to convert R to an integer between A and B.
!
  value = nint ( r, kind = 4 )

  value = max ( value, min ( a, b ) )
  value = min ( value, max ( a, b ) )

  i4_uniform = value

  return
end function i4_uniform


subroutine latin_random ( dim_num, point_num, seed, x )

!*****************************************************************************80
!
!! LATIN_RANDOM returns points in a Latin Random square.
!
!  Discussion:
!
!    In each spatial dimension, there will be exactly one
!    point whose coordinate value lies between consecutive
!    values in the list:
!
!      ( 0, 1, 2, ..., point_num ) / point_num
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license.
!
!  Modified:
!
!    08 April 2003
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) DIM_NUM, the spatial dimension.
!
!    Input, integer ( kind = 4 ) POINT_NUM, the number of points.
!
!    Input/output, integer ( kind = 4 ) SEED, a seed for the random number generator,
!    needed if the portable D_UNIFORM_01 routine is being used.
!
!    Output, real ( kind = 8 ) X(DIM_NUM,POINT_NUM), the points.
!
  implicit none

  integer ( kind = 4 ) dim_num
  integer ( kind = 4 ) point_num

  integer ( kind = 4 ) :: base = 1
  integer ( kind = 4 ) i
  integer ( kind = 4 ) j
  integer ( kind = 4 ) perm(point_num)
  real    ( kind = 8 ) r8_uniform_01
  integer ( kind = 4 ) seed
  real    ( kind = 8 ) x(dim_num,point_num)
!
!  Pick DIM_NUM * POINT_NUM random numbers between 0 and 1.
!
!  For fast results, use the FORTRAN90 standard RANDOM_NUMBER routine.
!  For reproductible results, use the UNIFORM routine.
!
  if ( .false. ) then

    call random_number ( harvest = x(1:dim_num,1:point_num) )

  else

    do i = 1, dim_num
      do j = 1, point_num
        x(i,j) = r8_uniform_01 ( seed )
      end do
    end do

  end if
!
!  For spatial dimension I, 
!    pick a random permutation of 1 to POINT_NUM,
!    force the corresponding I-th components of X to lie in the
!    interval ( PERM(J)-1, PERM(J) ) / POINT_NUM.
!
  do i = 1, dim_num

    call perm_uniform ( point_num, base, seed, perm )

    do j = 1, point_num
      x(i,j) = ( real ( perm(j) - 1, kind = 8 ) + x(i,j) ) &
               / real ( point_num, kind = 8 )
    end do

  end do

  return
end subroutine latin_random


subroutine perm_uniform ( n, base, seed, p )

!*****************************************************************************80
!
!! PERM_UNIFORM selects a random permutation of N objects.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license. 
!
!  Modified:
!
!    18 November 2008
!
!  Author:
!
!    John Burkardt
!
!  Reference:
!
!    Albert Nijenhuis, Herbert Wilf,
!    Combinatorial Algorithms,
!    Academic Press, 1978, second edition,
!    ISBN 0-12-519260-6.
!
!  Parameters:
!
!    Input, integer ( kind = 4 ) N, the number of objects to be permuted.
!
!    Input, integer ( kind = 4 ) BASE, is 0 for a 0-based permutation and 1 for 
!    a 1-based permutation.
!
!    Input/output, integer ( kind = 4 ) SEED, a seed for the random
!    number generator.
!
!    Output, integer ( kind = 4 ) P(N), the permutation.  P(I) is the "new"
!    location of the object originally at I.
!
  implicit none

  integer ( kind = 4 ) n

  integer ( kind = 4 ) base
  integer ( kind = 4 ) i
  integer ( kind = 4 ) i4_uniform
  integer ( kind = 4 ) j
  integer ( kind = 4 ) k
  integer ( kind = 4 ) p(n)
  integer ( kind = 4 ) seed

  do i = 1, n
    p(i) = ( i - 1 ) + base
  end do

  do i = 1, n
    j = i4_uniform ( i, n, seed )
    k    = p(i)
    p(i) = p(j)
    p(j) = k
  end do

  return
end subroutine perm_uniform


function r4_uniform_01 ( seed )

!*****************************************************************************80
!
!! R4_UNIFORM_01 returns a unit pseudorandom R4.
!
!  Discussion:
!
!    An R4 is a real ( kind = 4 ) value.
!
!    This routine implements the recursion
!
!      seed = 16807 * seed mod ( 2**31 - 1 )
!      r4_uniform_01 = seed / ( 2**31 - 1 )
!
!    The integer ( kind = 4 ) arithmetic never requires more than 32 bits,
!    including a sign bit.
!
!    If the initial seed is 12345, then the first three computations are
!
!      Input     Output      R4_UNIFORM_01
!      SEED      SEED
!
!         12345   207482415  0.096616
!     207482415  1790989824  0.833995
!    1790989824  2035175616  0.947702
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license.
!
!  Modified:
!
!    11 August 2004
!
!  Author:
!
!    John Burkardt
!
!  Reference:
!
!    Paul Bratley, Bennett Fox, Linus Schrage,
!    A Guide to Simulation,
!    Springer Verlag, pages 201-202, 1983.
!
!    Pierre L'Ecuyer,
!    Random Number Generation,
!    in Handbook of Simulation,
!    edited by Jerry Banks,
!    Wiley Interscience, page 95, 1998.
!
!    Bennett Fox,
!    Algorithm 647:
!    Implementation and Relative Efficiency of Quasirandom
!    Sequence Generators,
!    ACM Transactions on Mathematical Software,
!    Volume 12, Number 4, pages 362-376, 1986.
!
!    Peter Lewis, Allen Goodman, James Miller
!    A Pseudo-Random Number Generator for the System/360,
!    IBM Systems Journal,
!    Volume 8, pages 136-143, 1969.
!
!  Parameters:
!
!    Input/output, integer ( kind = 4 ) ( kind = 4 ) SEED, the "seed" value, which 
!    should NOT be 0.  On output, SEED has been updated.
!
!    Output, real ( kind = 4 ) R4_UNIFORM_01, a new pseudorandom variate,
!    strictly between 0 and 1.
!
  implicit none

  integer ( kind = 4 ) k
  integer ( kind = 4 ) seed
  real    ( kind = 4 ) r4_uniform_01

  if ( seed == 0 ) then
    write ( *, '(a)' ) ' '
    write ( *, '(a)' ) 'R4_UNIFORM_01 - Fatal error!'
    write ( *, '(a)' ) '  Input value of SEED = 0.'
    stop
  end if

  k = seed / 127773

  seed = 16807 * ( seed - k * 127773 ) - k * 2836

  if ( seed < 0 ) then
    seed = seed + 2147483647
  end if

  r4_uniform_01 = real ( seed, kind = 4 ) * 4.656612875E-10

  return
end function r4_uniform_01


function r8_uniform_01 ( seed )

!*****************************************************************************80
!
!! R8_UNIFORM_01 returns a unit pseudorandom R8.
!
!  Discussion:
!
!    An R8 is a real ( kind = 8 ) value.
!
!    For now, the input quantity SEED is an integer ( kind = 4 ) ( kind = 4 ) variable.
!
!    This routine implements the recursion
!
!      seed = 16807 * seed mod ( 2**31 - 1 )
!      r8_uniform_01 = seed / ( 2**31 - 1 )
!
!    The integer ( kind = 4 ) arithmetic never requires more than 32 bits,
!    including a sign bit.
!
!    If the initial seed is 12345, then the first three computations are
!
!      Input     Output      R8_UNIFORM_01
!      SEED      SEED
!
!         12345   207482415  0.096616
!     207482415  1790989824  0.833995
!    1790989824  2035175616  0.947702
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license.
!
!  Modified:
!
!    05 July 2006
!
!  Author:
!
!    John Burkardt
!
!  Reference:
!
!    Paul Bratley, Bennett Fox, Linus Schrage,
!    A Guide to Simulation,
!    Springer Verlag, pages 201-202, 1983.
!
!    Pierre L'Ecuyer,
!    Random Number Generation,
!    in Handbook of Simulation,
!    edited by Jerry Banks,
!    Wiley Interscience, page 95, 1998.
!
!    Bennett Fox,
!    Algorithm 647:
!    Implementation and Relative Efficiency of Quasirandom
!    Sequence Generators,
!    ACM Transactions on Mathematical Software,
!    Volume 12, Number 4, pages 362-376, 1986.
!
!    Peter Lewis, Allen Goodman, James Miller
!    A Pseudo-Random Number Generator for the System/360,
!    IBM Systems Journal,
!    Volume 8, pages 136-143, 1969.
!
!  Parameters:
!
!    Input/output, integer ( kind = 4 ) ( kind = 4 ) SEED, the "seed" value, which should
!    NOT be 0. On output, SEED has been updated.
!
!    Output, real ( kind = 8 ) R8_UNIFORM_01, a new pseudorandom variate,
!    strictly between 0 and 1.
!
  implicit none

  integer ( kind = 4 ) k
  real    ( kind = 8 ) r8_uniform_01
  integer ( kind = 4 ) seed

  if ( seed == 0 ) then
    write ( *, '(a)' ) ' '
    write ( *, '(a)' ) 'R8_UNIFORM_01 - Fatal error!'
    write ( *, '(a)' ) '  Input value of SEED = 0.'
    stop
  end if

  k = seed / 127773

  seed = 16807 * ( seed - k * 127773 ) - k * 2836

  if ( seed < 0 ) then
    seed = seed + 2147483647
  end if
!
!  Although SEED can be represented exactly as a 32 bit integer ( kind = 4 ),
!  it generally cannot be represented exactly as a 32 bit real number!
!
  r8_uniform_01 = real ( seed, kind = 8 ) * 4.656612875D-10

  return
end function r8_uniform_01


subroutine random_initialize ( seed )

!*****************************************************************************80
!
!! RANDOM_INITIALIZE initializes the FORTRAN 90 random number seed.
!
!  Discussion:
!
!    If you don't initialize the random number generator, its behavior
!    is not specified.  If you initialize it simply by:
!
!      call random_seed ( )
!
!    its behavior is not specified.  On the DEC ALPHA, if that's all you
!    do, the same random number sequence is returned.  In order to actually
!    try to scramble up the random number generator a bit, this routine
!    goes through the tedious process of getting the size of the random
!    number seed, making up values based on the current time, and setting
!    the random number seed.
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license.
!
!  Modified:
!
!    19 December 2001
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    Input/output, integer ( kind = 4 ) SEED.
!    If SEED is zero on input, then you're asking this routine to come up
!    with a seed value, which is returned as output.
!    If SEED is nonzero on input, then you're asking this routine to
!    use the input value of SEED to initialize the random number generator,
!    and SEED is not changed on output.
!
  implicit none

  integer ( kind = 4 ) count
  integer ( kind = 4 ) count_max
  integer ( kind = 4 ) count_rate
  logical, parameter :: debug = .false.
  integer ( kind = 4 ) i
  integer ( kind = 4 ) seed
  integer ( kind = 4 ), allocatable :: seed_vector(:)
  integer ( kind = 4 ) seed_size
  real    ( kind = 8 ) t
!
!  Initialize the random number seed.
!
  call random_seed ( )
!
!  Determine the size of the random number seed.
!
  call random_seed ( size = seed_size )
!
!  Allocate a seed of the right size.
!
  allocate ( seed_vector(seed_size) )

  if ( seed /= 0 ) then

    if ( debug ) then
      write ( *, '(a)' ) ' '
      write ( *, '(a)' ) 'RANDOM_INITIALIZE'
      write ( *, '(a,i20)' ) '  Initialize RANDOM_NUMBER, user SEED = ', seed
    end if

  else

    call system_clock ( count, count_rate, count_max )

    seed = count

    if ( debug ) then
      write ( *, '(a)' ) ' '
      write ( *, '(a)' ) 'RANDOM_INITIALIZE'
      write ( *, '(a,i20)' ) '  Initialize RANDOM_NUMBER, arbitrary SEED = ', &
        seed
    end if

  end if
!
!  Now set the seed.
!
  seed_vector(1:seed_size) = seed

  call random_seed ( put = seed_vector(1:seed_size) )
!
!  Free up the seed space.
!
  deallocate ( seed_vector )
!
!  Call the random number routine a bunch of times.
!
  do i = 1, 100
    call random_number ( harvest = t )
  end do

  return
end subroutine random_initialize



  function dinvnorm(p)

    implicit none

      real*8 :: dinvnorm,p,p_low,p_high
      real*8 :: a1,a2,a3,a4,a5,a6
      real*8 :: b1,b2,b3,b4,b5
      real*8 :: c1,c2,c3,c4,c5,c6
      real*8 :: d1,d2,d3,d4
      real*8 :: z,q,r
      a1=-39.6968302866538
      a2=220.946098424521
      a3=-275.928510446969
      a4=138.357751867269
      a5=-30.6647980661472
      a6=2.50662827745924
      b1=-54.4760987982241
      b2=161.585836858041
      b3=-155.698979859887
      b4=66.8013118877197
      b5=-13.2806815528857
      c1=-0.00778489400243029
      c2=-0.322396458041136
      c3=-2.40075827716184
      c4=-2.54973253934373
      c5=4.37466414146497
      c6=2.93816398269878
      d1=0.00778469570904146
      d2=0.32246712907004
      d3=2.445134137143
      d4=3.75440866190742
      p_low=0.02425
      p_high=1-p_low
      if(p.lt.p_low) goto 201
      if(p.ge.p_low) goto 301
201   q=dsqrt(-2*dlog(p))
      z=(((((c1*q+c2)*q+c3)*q+c4)*q+c5)*q+c6)/((((d1*q+d2)*q+d3)*q+d4)*q+1)
      goto 204
301   if((p.ge.p_low).and.(p.le.p_high)) goto 202
      if(p.gt.p_high) goto 302
202   q=p-0.5
      r=q*q
      z=(((((a1*r+a2)*r+a3)*r+a4)*r+a5)*r+a6)*q/(((((b1*r+b2)*r+b3)*r+b4)*r+b5)*r+1)
      goto 204
302   if((p.gt.p_high).and.(p.lt.1)) goto 203
203   q=dsqrt(-2*dlog(1-p))
      z=-(((((c1*q+c2)*q+c3)*q+c4)*q+c5)*q+c6)/((((d1*q+d2)*q+d3)*q+d4)*q+1)
204   dinvnorm=z

      return

    end function dinvnorm
